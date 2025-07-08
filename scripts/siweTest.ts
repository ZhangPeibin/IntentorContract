import { ethers } from "hardhat";
import axios from "axios";
import * as dotenv from "dotenv";
import path from "path";
import fs from "fs";

dotenv.config();

const VERIFY_API = process.env.VERIFY_API || 'http://localhost:3000/api/verify';
const wbnb = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const usdt = "0x55d398326f99059ff775485246999027b3197955"

async function getAiExecutor(chainId: number): Promise<string> {
  const aiExecutorConfigPath = path.resolve(__dirname, "../config/AiExecutor.json");
  if (!fs.existsSync(aiExecutorConfigPath)) {
    throw new Error(`❌ AiExecutor config file not found: ${aiExecutorConfigPath}`);
  }
  const aiExecutorConfig = JSON.parse(fs.readFileSync(aiExecutorConfigPath, "utf-8"));
  const aiExecutor = aiExecutorConfig[Number(chainId).toString()];

  if (!aiExecutor) {
    throw new Error(`❌ AiExecutor not found for chainId: ${chainId}`);
  }
  return aiExecutor.address;
}

async function getQuoter(chainId: number): Promise<string> {
  const quoterConfigPath = path.resolve(__dirname, "../config/Quoter.json");
  if (!fs.existsSync(quoterConfigPath)) {
    throw new Error(`❌ Quoter config file not found: ${quoterConfigPath}`);
  }
  const quoterConfig = JSON.parse(fs.readFileSync(quoterConfigPath, "utf-8"));
  const quoter = quoterConfig[Number(chainId).toString()];
  if (!quoter) {
    throw new Error(`❌ Quoter not found for chainId: ${chainId}`);
  }
  return quoter.quoter;
}

async function main() {
  const [user] = await ethers.getSigners();
  const { chainId } = await ethers.provider.getNetwork();
  console.log("👤 User Address:", user.address);
  // 1. 获取 nonce 和 SIWE 消息
  const signInfoRes = await axios.get(`${VERIFY_API}/signinfo`, {
    params: {
      address: user.address,
      chain: chainId,
    },
  });

  const { nonce, siwe } = signInfoRes.data;
  console.log("🌀 Nonce:", nonce);
  console.log("📜 SIWE message:", siwe);

  // 2. 签名 SIWE 消息
  const signature = await user.signMessage(siwe);
  console.log("✍️ Signature:", signature);

  // 3. 调用 verify 接口
  const verifyRes = await axios.post(`${VERIFY_API}`, {
    message: siwe,
    signature,
  });

  const token = verifyRes.data.token;
  console.log("✅ Verify Response:", verifyRes.data);
  console.log("🔐 JWT Token:", token);

  // 4. 调用 /api/intent 接口，带参数和 JWT
  const INTENT_API = VERIFY_API.replace('/api/verify', '/api/intent');

  const intentPayload = {
    message: "帮我bsc上通过uni用0.0001bnb买usdt",
    wallet: user.address,
  };

  const intentVerifyRes = await axios.post(INTENT_API, intentPayload, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });


  console.log("🤖 Intent Verify Response:", intentVerifyRes.data);

  const intent = intentVerifyRes.data
  intent.receiver = user.address;//okx wallet 2
  intent.exactInput = true;
  intent.platform = "uni";
  intent.fromToken = wbnb; // USDT
  intent.toToken = usdt;

  const quoterAddress = await getQuoter(Number(chainId));
  console.log("🤖 Quoter Address:", quoterAddress);
  const quoterContract = await ethers.getContractAt('IBaseQuoter', quoterAddress);


  const amount = await quoterContract.quoteExactInput.staticCall({
    dex: intent.platform,
    tokenIn: intent.fromToken,
    tokenOut: intent.toToken,
    amount: ethers.parseUnits(intent.amount, 18), // 1 USDT
    fee: 3000, // Uniswap V3 fee tier 
  });

  intent.amountMinout = amount.toString();

  const amountInWei = ethers.parseUnits(intent.amount, 18);
  // slippage 加成（用 BigInt 实现 乘1.1）
  const multiplied = (amountInWei * BigInt(Math.floor(1.1 * 10000))) / BigInt(10000);

  intent.amount = multiplied.toString();

  const aiExecutorAddress = await getAiExecutor(Number(chainId));
  console.log("🤖 AiExecutor Address:", aiExecutorAddress);

  const aiExecutor = await ethers.getContractAt('AiExecutor', aiExecutorAddress);
  console.log("🤖 AiExecutor Dex Contract:", await aiExecutor.getRouterByDex('uni'));


  if (intent.fromToken !== wbnb) {
    const result = await aiExecutor.connect(user).validate(intent as any, 0);
    console.log("✅ Intent Validation Result:", result);

    const fromTokenContract = await ethers.getContractAt('IERC20', intent.fromToken);
    if (result[1] === 1n) {
      await fromTokenContract.connect(user).approve(aiExecutor.target, intent.amount);
      const result = await aiExecutor.connect(user).validate(intent as any, 0);
      console.log("✅ Intent Validation Result:", result);
    }

    intent.toToken = ethers.ZeroAddress;
    intent.amount = Number(intent.amount).toString()
    console.log("Intent", intent)
  } else {
    intent.fromToken = ethers.ZeroAddress;
    const balance = await ethers.provider.getBalance(user.address);
    const result = await aiExecutor.connect(user).validate(intent as any, intent.amount);
    console.log("✅ Intent Validation Result:", result);
  }

  console.log("🤖 Executing intent :", intent);
  await aiExecutor.connect(user).execute(intent as any, { value: intent.amount });
}

// 入口
main().catch((error) => {
  console.error("❌ Error:", error);
  process.exitCode = 1;
});
