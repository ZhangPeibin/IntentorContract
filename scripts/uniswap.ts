import { ethers } from "hardhat";

const bscRouter = "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2"
const unidex = '0x09F615b77d40c011C053b9335D052B9B03a4946f'

const wbnb = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const usdt = "0x55d398326f99059ff775485246999027b3197955"
const depolyQuoter = "0x70b938f66C7429242A4301a44075ca65638d06c6";

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

    const from = ethers.ZeroAddress; // 发送BNB作为gas费
    const to = usdt;
    const amount = ethers.parseEther("1"); // 0.1 USDT


    if (from !== ethers.ZeroAddress) {
        const fromToken = await ethers.getContractAt("IERC20", from);

        const balance = await fromToken.balanceOf(user.address);

        console.log("💰 token from  Address:", from);
        console.log("💰 token from  Balance:", ethers.formatEther(balance))
        const allowance = await fromToken.allowance(user.address, uniDex.target);

        if (allowance < balance) {
            console.log("❗️ Insufficient allowance, approving...");
            console.log("💰 token from  Allowance:", ethers.formatEther(allowance));
            await fromToken.approve(uniDex.target, balance);
        }
    }

    // const quoter = await ethers.getContractAt("Quoter", depolyQuoter);
    // const r = await quoter.quoteExactInput.staticCall({    
    //     dex: 'uni',
    //     tokenIn: from,
    //     tokenOut: wbnb,
    //     amount: amount, // 0.1 USDT
    //     fee: 3000, // 0.3%
    // });
    // console.log("📊 Quote Result:", ethers.formatEther(r.toString()));
    // // test swap token to bnb
    // const txt = await uniDex.swap(
    //     from,
    //     to,
    //     ethers.parseEther("0.1"), 
    //     r, // minAmountOut
    //     user.address,
    //     true// 发送BNB作为gas费
    // );
    // const receipt = await txt.wait();
    // console.log("✅ Swap Transaction Hash:", receipt);

    // test swap bnb to token 
    // const txt = await uniDex.swap(
    //     from,
    //     to,
    //     ethers.parseEther("0.001"),
    //     0, // minAmountOut
    //     user.address,
    //     true,// 发送BNB作为gas费,
    //     {
    //         value: ethers.parseEther("0.001") // 发送0.01 BNB作为gas费
    //     }
    // );


    // exact out 
    const quoter = await ethers.getContractAt("Quoter", depolyQuoter);
    const r = await quoter.quoteExactOutput.staticCall({
        dex: 'uni',
        tokenIn: wbnb,
        tokenOut: to,
        amount: amount, // 0.1 USDT
        fee: 3000, // 0.3%
    });
    console.log("📊 Quote Result:", ethers.formatEther(r.toString()));

    const txt = await uniDex.swap(
        from,
        to,
        r,
        amount, // minAmountOut
        user.address,
        false,// 发送BNB作为gas费,
        {
            value: r // 发送0.01 BNB作为gas费
        }
    );
    const receipt = await txt.wait();
    console.log("✅ Swap Transaction Hash:", receipt);
}
// 入口
main().catch((error) => {
    console.error("❌ Error:", error);
    process.exitCode = 1;
});
