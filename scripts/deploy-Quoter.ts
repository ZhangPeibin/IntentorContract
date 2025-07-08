import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";

//bsc
const uniQuoter = "0x78D78E420Da98ad378D7799bE8f4AF69033EB077";
// 保存 Quoter 地址到配置文件
const configDir = "./config";
const configPath = `${configDir}/quoter.json`;

async function geRouter(chainId: number): Promise<any> {
    const routerConfigPath = path.resolve(__dirname, "../config/router.json");
    if (!fs.existsSync(routerConfigPath)) {
        throw new Error(`❌ Router config file not found: ${routerConfigPath}`);
    }
    const routerConfig = JSON.parse(fs.readFileSync(routerConfigPath, "utf-8"));
    const router = routerConfig[Number(chainId).toString()];
    if (!router) {
        throw new Error(`❌ Router not found for chainId: ${chainId}`);
    }
    return router;
}

async function getQuoter(chainId: number): Promise<string> {
    const quoterConfigPath = path.resolve(__dirname, "../config/quoter.json");
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
    const [deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();

    console.log("👤 Deployer Address:", deployer.address);
    console.log("🌐 Network ChainId:", chainId);

    const Quoter = await ethers.getContractFactory("Quoter");
    const quoter = await Quoter.deploy(deployer.address);
    await quoter.waitForDeployment();
    console.log("📦 Quoter deployed to:", quoter.target);



    fs.mkdirSync(configDir, { recursive: true });
    let config: Record<string, {}> = {};
    if (fs.existsSync(configPath)) {
        config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    }
    config[chainId.toString()] = { quoter: quoter.target as string };
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));



    await quoter.updateQuoter('uni', uniQuoter);
    const quoterRouter = await quoter.quoterFromDex('uni');
    console.log("📦 Quoter Router Address:", quoterRouter);
    if (quoterRouter !== uniQuoter) {
        throw new Error("❌ Quoter Router Address does not match the deployed router address");
    }

    // 修改quoter.json isConfigRouter
    config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    config[chainId.toString()].isConfigRouter = true;
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}


async function updateDexQuoter() {
    const { chainId } = await ethers.provider.getNetwork();
    const quoter = await getQuoter(Number(chainId));
    const Quoter = await ethers.getContractAt("Quoter", quoter);
    await Quoter.updateQuoter('uni', uniQuoter);
    console.log("✅ Updated Uni Quoter Address:", uniQuoter);
    const quoterRouter = await Quoter.quoterFromDex('uni');

    if (quoterRouter !== uniQuoter) {
        throw new Error("❌ Quoter Router Address does not match the deployed router address");
    }

    let config: Record<string, {}> = {};
    if (fs.existsSync(configPath)) {
        config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    }
    config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    config[chainId.toString()].isConfigRouter = true;
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}

updateDexQuoter().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
});