import { ethers } from "hardhat";
import {abi} from "../artifacts/contracts/dex/Quoter.sol/Quoter.json";

const depolyQuoter = "0x70b938f66C7429242A4301a44075ca65638d06c6";
const uniQuoter = "0x78D78E420Da98ad378D7799bE8f4AF69033EB077";

async function main() {
  // ✅ 创建 provider 和 signer（从 .env 加载私钥）
  const [user] = await ethers.getSigners();
  const quoter = await ethers.getContractAt(abi, depolyQuoter);
  // ✅ 查询 Quoter 地址
  const uniQuoterAddress = await quoter.quoterFromDex('uni');
  console.log("📦 Uni Quoter Address:", uniQuoterAddress);

  // ✅ 构建 quote 参数
  const exactInput = {
    dex: 'uni',
    tokenIn: '0x55d398326f99059ff775485246999027b3197955', // USDT
    tokenOut: '0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c', // USDC
    amount: ethers.parseUnits('1', 18), // 1 USDT
    fee: 3000,
  };
  // ✅ 使用 callStatic 查询报价
  const quote = await quoter.quoteExactInput.staticCall(exactInput);
  console.log("📊 Quote Result:", quote.toString());

  const exactOut = {
    dex: 'uni',
    tokenIn: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c', // USDT
    tokenOut: '0x55d398326f99059ff775485246999027b3197955', // USDC
    amount: ethers.parseUnits('1', 18), // 1 USDT
    fee: 3000,
  };
  // ✅ 使用 callStatic 查询报价
  const quoteOut = await quoter.quoteExactOutput.staticCall(exactOut);
  console.log("📊 Quote Result:", quoteOut.toString());

}

main().catch((error) => {
    console.error("❌ Error:", error);
    process.exitCode = 1;
});
