import { ethers } from "hardhat";
import { dex } from "../typechain-types/contracts";

const uniQuoter = "0xA4aa4849A8782e8768C4ba25dc4eFa1F86b7F1B9"
const AI_EXECUTOR = '0x9495E5bD1f23b05Af64DDcd040FD1f2805300701'

async function exactInput() {
    const [user] = await ethers.getSigners();
    console.log("👤 User Address:", user.address);
    const AISwap = await ethers.getContractAt("AiExecutor", AI_EXECUTOR);

    const amount = ethers.parseEther("1"); // 0.1 USDT
    const token0 = "0x55d398326f99059ff775485246999027b3197955";
    const token1 = "0xba2ae424d960c26247dd6c32edc70b295c744c43";

    const fee = await ethers.getContractAt("Fee", "0x8247d324a0F8eF218b094b759C13D034Cfc7efAE");
    const swapFee = await fee.estimateFee(user.address, token0, amount);
    console.log("💰 Swap Fee:", ethers.formatEther(swapFee.toString()));

    const quoter = await ethers.getContractAt("Quoter", uniQuoter);
    const restAmount = amount - swapFee; 1
    console.log("💰 Rest Amount after Fee:", ethers.formatEther(restAmount.toString()));
    const exactInput = {
        tokenIn: token0, // USDT
        tokenOut: token1, // doge
        amount: restAmount, // 1 USDT
        dex: 0,
    };
    // ✅ 使用 callStatic 查询报价
    const quote = await quoter.quoteExactInput.staticCall(exactInput);
    console.log("📊 Quote Result:", quote.toString());
    //return;
    if (token0 !== ethers.ZeroAddress) {
        const fromToken = await ethers.getContractAt("IERC20", token0);

        const balance = await fromToken.balanceOf(user.address);

        console.log("💰 token from  Address:", token0);
        console.log("💰 token from  Balance:", ethers.formatEther(balance))
        const allowance = await fromToken.allowance(user.address, AISwap.target);
        console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
        if (allowance < balance) {
            console.log("❗️ Insufficient allowance, approving...");
            console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
            await fromToken.approve(AISwap.target, balance);
        }
    }
    const swapParams = {
        amount: amount, // 1 USDT
        amountMinout: quote[0], // 最小输出金额
        fromToken: token0, // USDT    
        toToken: token1, // doge
        refundTo: user.address, // 退款地址
        poolFee: quote[1], // 池子费用
        chainId: 56, // BSC Chain ID
        exactInput: true, // 精确输入
        dex: 0
    }

    console.log("🔄 Swap Parameters:", swapParams);
    const txt = await AISwap.execute(swapParams, { gasLimit: 5000000 });
    const receipt = await txt.wait();
    console.log("✅ Swap Transaction Hash:", receipt);
}

async function exactOutput() {
    const [user] = await ethers.getSigners();
    console.log("👤 User Address:", user.address);
    const AISwap = await ethers.getContractAt("AiExecutor", AI_EXECUTOR);

  
    const swapParams = {
        amount: '2450532960857586902', // 1 USDT
        amountMinout:'1000000000', // 最小输出金额
        fromToken: '0x55d398326f99059ff775485246999027b3197955', // USDT    
        toToken: '0xba2ae424d960c26247dd6c32edc70b295c744c43', // doge
        refundTo: user.address, // 退款地址
        poolFee: 10000, // 池子费用
        chainId: 56, // BSC Chain ID
        exactInput: false, // 精确输入
        dex: 0
    }

    console.log("🔄 Swap Parameters:", swapParams);
    const txt = await AISwap.execute(swapParams, { gasLimit: 5000000 });
    const receipt = await txt.wait();
    console.log("✅ Swap Transaction Hash:", receipt);

}


// 入口
exactOutput().catch((error) => {
    console.error("❌ Error:", error);
    process.exitCode = 1;
});
