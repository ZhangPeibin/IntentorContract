import { ethers } from "hardhat";
import axios from "axios";
import * as dotenv from "dotenv";
import path from "path";
import fs from "fs";

dotenv.config();

const VERIFY_API = process.env.VERIFY_API || 'http://localhost:3000/api/verify';


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

async function main() {
  const [deployer, admin, user] = await ethers.getSigners();
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
    message: "给我买20u的TEST代币在quickswap上面",
    wallet: user.address,
  };

  const intentVerifyRes = await axios.post(INTENT_API, intentPayload, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });


  console.log("🤖 Intent Verify Response:", intentVerifyRes.data);

  const mockUSDT = await ethers.deployContract('MockUSDT', [100]);
  const intent = intentVerifyRes.data
  intent.fromToken = mockUSDT.target;
  intent.toToken = mockUSDT.target;

  const aiExecutorAddress = await getAiExecutor(Number(chainId));
  console.log("🤖 AiExecutor Address:", aiExecutorAddress);
  
  const aiExecutor = await ethers.getContractAt('AiExecutor', aiExecutorAddress);
  console.log("🤖 AiExecutor Dex Contract:",await aiExecutor.getRouterByDex('uni'));

  //mint token
  await mockUSDT.connect(user).mint();
  console.log("intnet:", intent);

  /**
   *    struct IntentReq {
        address receiver;
        uint256 amountMinout;
        bool exactInput;
        string intent;
        string platform;
        address fromToken;
        address toToken;
        uint256 amount;
        uint32 chainId;
    }
   */
  intent.receiver = user.address;
  intent.amountMinout = ethers.parseUnits("20", 6); 
  intent.exactInput = true;
  intent.platform = "quickswap";
  intent.chainId = chainId;
  const result = await aiExecutor.connect(user).validate(intent as any,0);

  console.log("✅ Intent Validation Result:", result);
  if (result[1] === 1n) {
    await mockUSDT.connect(user).approve(aiExecutor.target, ethers.parseUnits(intent.amount, 18));
    const result = await aiExecutor.connect(user).validate(intent as any,0);
    console.log("✅ Intent Validation Result:", result);
  }
}

// 入口
main().catch((error) => {
  console.error("❌ Error:", error);
  process.exitCode = 1;
});
