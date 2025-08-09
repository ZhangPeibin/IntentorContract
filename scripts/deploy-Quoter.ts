import { ethers } from "hardhat";
import * as fs from "fs";

import { assert } from "console";

//bsc
const uniQuoter = "0x78D78E420Da98ad378D7799bE8f4AF69033EB077";
const uniFactory = "0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7";

const configDir = "./config";
const configPath = `${configDir}/quoter.json`;



async function main() {
    const [deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();

    console.log("👤 Deployer Address:", deployer.address);
    console.log("🌐 Network ChainId:", chainId);
    fs.mkdirSync(configDir, { recursive: true });
    let config: Record<string, {}> = {};
    if (fs.existsSync(configPath)) {
        config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    }
    let depolyedQuoter = config[chainId.toString()]?.quoter;
    console.log("fetch depolyedQuoter:", depolyedQuoter);
    if (!depolyedQuoter) {
        const QuoterFactory = await ethers.getContractFactory("Quoter");
        const quoter = await QuoterFactory.deploy(deployer.address);
        await quoter.waitForDeployment();
        console.log("📦 Quoter deployed to:", quoter.target);
        config[chainId.toString()] = { quoter: quoter.target as string };
        fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
        depolyedQuoter = quoter.target;
    }
    const quoter = await ethers.getContractAt("Quoter", depolyedQuoter);

    await quoter.setDexInfo(0, uniQuoter, uniFactory);
    const dexInfo = await quoter.dexInfos(0);
    console.log("📦 Quoter Router Address:", dexInfo);
    assert(dexInfo[0] === uniQuoter, "❌ Quoter Router Address does not match");
    assert(dexInfo[1] === uniFactory, "❌ Quoter Router Address does not match");

    // // 修改quoter.json isConfigRouter
    config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    config[chainId.toString()].uniQuoter = uniQuoter;
    config[chainId.toString()].uniFactory = uniFactory;

    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}


async function updateDexQuoter() {
    const { chainId } = await ethers.provider.getNetwork();
    const quoter = await getQuoter(Number(chainId));
    const Quoter = await ethers.getContractAt("Quoter", quoter);
    await Quoter.setDexInfo(0, uniQuoter, uniFactory);
    console.log("✅ Updated Uni Quoter Address:", uniQuoter);
    const quoterRouter = await Quoter.dexInfos(0);



    let config: Record<string, {}> = {};
    if (fs.existsSync(configPath)) {
        config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    }
    config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    config[chainId.toString()].isConfigRouter = true;
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}


main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
});