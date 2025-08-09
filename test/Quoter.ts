import { ethers } from "hardhat";
import { getQuoter } from "../scripts/utils/depolyUtil";

async function main() {
  // ✅ 创建 provider 和 signer（从 .env 加载私钥）
  const [user] = await ethers.getSigners();
  const { chainId } = await ethers.provider.getNetwork();
  const depolyedQuoter = await getQuoter(Number(chainId));
  console.log("👤 User Address:", user.address);
  console.log("🌐 Network ChainId:", chainId);
  console.log("📦 Deployed Quoter Address:", depolyedQuoter);
  const quoter = await ethers.getContractAt('Quoter', depolyedQuoter);
  const dexInfos = await quoter.dexInfos(0);
  console.log("📊 Dex Infos:", dexInfos);

  const pool = await quoter.poolFee("0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7",
    '0x55d398326f99059ff775485246999027b3197955', // USDT
    '0xba2ae424d960c26247dd6c32edc70b295c744c43', // doge
  );
  console.log("📊 Pool Fee:", pool.toString());


  // ✅ 构建 quote 参数
  const exactInput = {
    tokenIn: '0x55d398326f99059ff775485246999027b3197955', // USDT
    tokenOut: '0xba2ae424d960c26247dd6c32edc70b295c744c43', // doge
    amount: ethers.parseUnits('1', 18), // 1 USDT
    dex: 0,
  };
  // ✅ 使用 callStatic 查询报价
  const quote = await quoter.quoteExactInput.staticCall(exactInput);
  console.log("📊 Quote Result:", quote.toString());

  const exactOut = {
    dex: 0,
    tokenIn: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c', // USDT
    tokenOut: '0xba2ae424d960c26247dd6c32edc70b295c744c43', // USDC
    amount: ethers.parseUnits('1', 6), // 1 USDT
  };
  // ✅ 使用 callStatic 查询报价
  const quoteOut = await quoter.quoteExactOutput.staticCall(exactOut);
  console.log("📊 Quote Result:", quoteOut.toString());

}

main().catch((error) => {
  console.error("❌ Error:", error);
  process.exitCode = 1;
});
