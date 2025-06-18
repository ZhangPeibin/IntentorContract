import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";


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


async function main() {
    const [deployer] = await ethers.getSigners();
    const { chainId } = await ethers.provider.getNetwork();
    
    console.log("👤 Deployer Address:", deployer.address);
    console.log("🌐 Network ChainId:", chainId);

    const Quoter = await ethers.getContractFactory("Quoter");
    const quoter = await Quoter.deploy(deployer.address);
    await quoter.waitForDeployment();
    console.log("📦 Quoter deployed to:", quoter.target);

        
    // 保存 Quoter 地址到配置文件
    const configDir = "./config";   
    const configPath = `${configDir}/quoter.json`;
    fs.mkdirSync(configDir, { recursive: true });
    let config: Record<string, {}> = {};
    if (fs.existsSync(configPath)) {
        config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    }       
    config[chainId.toString()] = { quoter: quoter.target as string };
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));


    const router = await geRouter(Number(chainId));
    console.log("🌐 Router Address:", router.address);
    await quoter.updateQuoter('uni', router.address);
    console.log("✅ Updated Uni Quoter Address:", router.address);
    const quoterRouter = await quoter.quoterFromDex('uni');
    console.log("📦 Quoter Router Address:", quoterRouter);
    if( quoterRouter !== router.address) {
        throw new Error("❌ Quoter Router Address does not match the deployed router address");
    }

    // 修改quoter.json isConfigRouter
    config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    config[chainId.toString()].isConfigRouter = true;
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}

main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
});