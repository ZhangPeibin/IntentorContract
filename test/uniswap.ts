import { ethers } from "hardhat";

const uniDexAddress = '0x75ea460f210E1382d0495C8f43Ab4fF140Cdf2df'
const uniQuoter = "0xA4aa4849A8782e8768C4ba25dc4eFa1F86b7F1B9";

const wbnb = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const usdt = "0x55d398326f99059ff775485246999027b3197955"



async function exactInput() {
    const [user] = await ethers.getSigners();
    console.log("👤 User Address:", user.address);
    const uniDex = await ethers.getContractAt("Uniswap", uniDexAddress);
    const isWhiteList = await uniDex.isWhitelisted(user.address);
    console.log("✅ Is Whitelisted:", isWhiteList);
    if (!isWhiteList) {
        await uniDex.setSwapWhitelistSingle(user.address, true);
    }

    const amount = ethers.parseEther("1"); // 0.1 USDT
    const token0 = "0x55d398326f99059ff775485246999027b3197955";
    const token1 = "0xba2ae424d960c26247dd6c32edc70b295c744c43";

    const fee = await ethers.getContractAt("Fee", "0x8247d324a0F8eF218b094b759C13D034Cfc7efAE");
    const swapFee = await fee.estimateFee(user.address, token0, amount);
    console.log("💰 Swap Fee:", ethers.formatEther(swapFee.toString()));

    const quoter = await ethers.getContractAt("Quoter", uniQuoter);
    const restAmount = amount - swapFee; // 扣除手续费后的实际交易金额
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
        const allowance = await fromToken.allowance(user.address, uniDex.target);
        console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
        if (allowance < balance) {
            console.log("❗️ Insufficient allowance, approving...");
            console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
            await fromToken.approve(uniDex.target, balance);
        }
    }
    const swapParams = {
        amountIn: amount, // 1 USDT
        amountOutMinimum: quote[0], // 最小输出金额
        tokenIn: token0, // USDT    
        tokenOut: token1, // doge
        refundTo: user.address, // 退款地址
        poolFee: quote[1], // 池子费用
        exactInput: true, // 精确输入
    }
    const txt = await uniDex.swap(swapParams);
    const receipt = await txt.wait();
    console.log("✅ Swap Transaction Hash:", receipt);
}


async function exactOut() {
    const [user] = await ethers.getSigners();
    console.log("👤 User Address:", user.address);
    const uniDex = await ethers.getContractAt("Uniswap", uniDexAddress);
    const isWhiteList = await uniDex.isWhitelisted(user.address);
    console.log("✅ Is Whitelisted:", isWhiteList);
    if (!isWhiteList) {
        await uniDex.setSwapWhitelistSingle(user.address, true);
    }

    const amount = ethers.parseUnits('4.27573', 8); // 0.1 USDT
    const token0 = "0x55d398326f99059ff775485246999027b3197955";
    const token1 = "0xba2ae424d960c26247dd6c32edc70b295c744c43";
    console.log("💰 Swap Amount:", amount);
    const fee = await ethers.getContractAt("Fee", "0x8247d324a0F8eF218b094b759C13D034Cfc7efAE");
    const swapFee = await fee.estimateFee(user.address, token1, amount);
    console.log("💰 Swap Fee:", swapFee);
    const quoter = await ethers.getContractAt("Quoter", uniQuoter);
    const restAmount = amount - swapFee; // 扣除手续费后的实际交易金额
    console.log("💰 Rest Amount after Fee:",restAmount.toString());
    const exactOut = {
        tokenIn: token0, // USDT
        tokenOut: token1, // doge
        amount: amount, // 1 USDT
        dex: 0,
    };
    // ✅ 使用 callStatic 查询报价
    const quote = await quoter.quoteExactOutput.staticCall(exactOut);
    console.log("📊 Quote Result:", quote.toString());
    
    const swapParams = {
        amountIn: quote[0], // 1 USDT
        amountOutMinimum: amount, // 最小输出金额
        tokenIn: token0, // USDT    
        tokenOut: token1, // doge
        refundTo: user.address, // 退款地址
        poolFee: quote[1], // 池子费用
        exactInput: false, // 精确输入
    }
    console.log("💰 Swap Params:", swapParams);
    const txt = await uniDex.swap(swapParams);
    const receipt = await txt.wait();
    console.log("✅ Swap Transaction Hash:", receipt);
}


async function exactOutFromDogeToBNB() {
    const [user] = await ethers.getSigners();
    console.log("👤 User Address:", user.address);
    const uniDex = await ethers.getContractAt("Uniswap", uniDexAddress);
    const isWhiteList = await uniDex.isWhitelisted(user.address);
    console.log("✅ Is Whitelisted:", isWhiteList);
    if (!isWhiteList) {
        await uniDex.setSwapWhitelistSingle(user.address, true);
    }

    const token0 = "0xba2ae424d960c26247dd6c32edc70b295c744c43";
    const token1 = '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c';
    //get all doge 
    const token0ERC20 = await ethers.getContractAt("IERC20", token0);
    const balance = await token0ERC20.balanceOf(user.address);
    console.log("💰 token from  Balance:",balance)
    const amount =balance; // 0.1 USDT

    console.log("💰 Swap Amount:", amount);
    const fee = await ethers.getContractAt("Fee", "0x8247d324a0F8eF218b094b759C13D034Cfc7efAE");
    const swapFee = await fee.estimateFee(user.address, token1, amount);
    console.log("💰 Swap Fee:", swapFee);
    const quoter = await ethers.getContractAt("Quoter", uniQuoter);
    const restAmount = amount - swapFee; // 扣除手续费后的实际交易金额
    console.log("💰 Rest Amount after Fee:",restAmount.toString());
    const exactOut = {
        tokenIn: token0, // USDT
        tokenOut: token1, // doge
        amount: amount, // 1 USDT
        dex: 0,
    };
    // ✅ 使用 callStatic 查询报价
    const quote = await quoter.quoteExactOutput.staticCall(exactOut);
    console.log("📊 Quote Result:", quote.toString());

       if (token0 !== ethers.ZeroAddress) {
        const fromToken = await ethers.getContractAt("IERC20", token0);

        const balance = await fromToken.balanceOf(user.address);

        console.log("💰 token from  Address:", token0);
        console.log("💰 token from  Balance:", ethers.formatEther(balance))
        const allowance = await fromToken.allowance(user.address, uniDex.target);
        console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
        if (allowance < balance) {
            console.log("❗️ Insufficient allowance, approving...");
            console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
            await fromToken.approve(uniDex.target, balance);
        }
    }
    
    const swapParams = {
        amountIn: amount, // 1 USDT
        amountOutMinimum: quote[0], // 最小输出金额
        tokenIn: token0, // USDT    
        tokenOut: token1, // doge
        refundTo: user.address, // 退款地址
        poolFee: quote[1], // 池子费用
        exactInput: true, // 精确输入
    }
    console.log("💰 Swap Params:", swapParams);
    const txt = await uniDex.swap(swapParams);
    const receipt = await txt.wait();
    console.log("✅ Swap Transaction Hash:", receipt);
}
// 入口
exactOutFromDogeToBNB().catch((error) => {
    console.error("❌ Error:", error);
    process.exitCode = 1;
});
