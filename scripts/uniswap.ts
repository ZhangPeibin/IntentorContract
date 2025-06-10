import { ethers } from "hardhat";

const bscRouter = "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2"
const unidex = '0xDd95Bad43707c51a8938b659DE9cefd1363dA0Fc'

const wbnb = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const usdt = "0x55d398326f99059ff775485246999027b3197955"

async function depoly() {
    const [user] = await ethers.getSigners();
    const chainId = 56;
    console.log("👤 User Address:", user.address);
    const dex = await ethers.deployContract('Uniswap', [bscRouter, wbnb]);
    const tx = await dex.waitForDeployment();
    console.log("📦 Contract Address:", tx.target);
}

async function config() {
    const [user] = await ethers.getSigners();
    const uniDex = await ethers.getContractAt("Uniswap", unidex);

    const isWhiteList = await uniDex.isWhitelisted(user.address);
    if (!isWhiteList) {
        await uniDex.setSwapWhitelistSingle(user.address, true);
    }
}

async function main() {
    const [user] = await ethers.getSigners();
    const uniDex = await ethers.getContractAt("Uniswap", unidex);
    await config();
    const isWhiteList = await uniDex.isWhitelisted(user.address);
    console.log("👤 User Address:", user.address);
    console.log("✅ Is Whitelisted:", isWhiteList);

    const from = wbnb;
    const to = usdt;

    const fromToken = await ethers.getContractAt("IERC20", wbnb);
    const balance = await fromToken.balanceOf(user.address);
    console.log("💰 token from  Balance:", ethers.formatEther(balance))
    const allowance = await fromToken.allowance(user.address, uniDex.target);

    if (allowance < balance) {
        console.log("❗️ Insufficient allowance, approving...");
        console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
        await fromToken.approve(uniDex.target, balance);
    }

    console.log("✅ USDT Approved for Uniswap");
    const tx = await uniDex.swap(
        from, // BNB    
        to, // USDT
        balance, // 发送0.01 USDT 
        0, // 最小接收BNB数量
        true, // 接收地址
        { gasLimit: 3000000 } // 设置gas limit
    );
    await tx.wait();
}
// 入口
main().catch((error) => {
    console.error("❌ Error:", error);
    process.exitCode = 1;
});
