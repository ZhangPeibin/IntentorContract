import { ethers, upgrades } from "hardhat";
import * as fs from "fs";
import * as path from "path";

const feeConfigPath = path.resolve(__dirname, "../config/fee.json");
const dexConfigPath = path.resolve(__dirname, "../config/router.json");
const aiExecutorConfigPath = path.resolve(__dirname, "../config/AiExecutor.json");

async function getDex(chainId: number): Promise<any> {
    if (!fs.existsSync(dexConfigPath)) {
        throw new Error(`❌ Dex config file not found: ${dexConfigPath}`);
    }
    const dexConfig = JSON.parse(fs.readFileSync(dexConfigPath, "utf-8"));
    const dex = dexConfig[Number(chainId).toString()];
    if (!dex) {
        throw new Error(`❌ Dex  not found for chainId: ${chainId}`);
    }
    return dex;
}



async function saveAiExecutorConfig(chainId: number, address: string) {
  const configDir = path.join(__dirname, "../config");

  fs.mkdirSync(configDir, { recursive: true });

  let config: Record<string, {}> = {};
  if (fs.existsSync(aiExecutorConfigPath)) {
    config = JSON.parse(fs.readFileSync(aiExecutorConfigPath, "utf-8"));
  }

  config[chainId.toString()] = { address: address };

  fs.writeFileSync(aiExecutorConfigPath, JSON.stringify(config, null, 2));
  console.log(`📄 Aiexecutor address saved under chainId ${chainId} at: ${aiExecutorConfigPath}`);
}

async function main() {

    const [deployer] = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();
    const chainId = network.chainId;

    console.log("👤 Deployer:", deployer.address);
    console.log("🌐 Network ChainId:", chainId);
    //red fee info 
    if (!fs.existsSync(feeConfigPath)) {
        throw new Error(`❌ Fee config file not found: ${feeConfigPath}`);
    }

    const feeConfig = JSON.parse(fs.readFileSync(feeConfigPath, "utf-8"));
    console.log(feeConfig)
    const feeAddress = feeConfig[Number(chainId).toString()];
    if (!feeAddress) throw new Error("❌ Fee address not found in config");
    const fee = feeAddress.fee;
    if (!fee) throw new Error("❌ Fee address not found in config");
    console.log("Fee address:", fee)

    const AIExecutor = await ethers.getContractFactory("AiExecutor");
    const aiExecutor = await upgrades.deployProxy(
        AIExecutor,
        [deployer.address, fee],
        { initializer: "__AIExecutor_init" }
    );
    await aiExecutor.waitForDeployment();
    console.log(`✅ AiExecutor deployed at proxy address: ${aiExecutor.target}`);

    //config fee contract
    const FeeContract = await ethers.getContractAt('Fee', fee);
    await FeeContract.setAIExecutor(aiExecutor.target);
    const aiExecutorInFee = await FeeContract.aiExecutor();
    console.log('✅ AiExecutor In Fee Contract:' + aiExecutorInFee)

    //config dex 
    const dex = await getDex(Number(chainId));
    console.log("✅ Dex Address:", dex.address);
    const UniSwap = await ethers.getContractAt('IDex', dex.address);
    await UniSwap.setSwapWhitelistSingle(aiExecutor.target, true);
    const isWhitelisted = await UniSwap.isWhitelisted(aiExecutor.target);
    console.log(`✅ AiExecutor is whitelisted in Dex: ${isWhitelisted}`);


    // 更新 fee.json
    if (aiExecutorInFee === aiExecutor.target) {
        const feeData = fs.existsSync(feeConfigPath) ? JSON.parse(fs.readFileSync(feeConfigPath, "utf8")) : {};
        feeData[chainId.toString()].isConfigExecutor = true;
        fs.writeFileSync(feeConfigPath, JSON.stringify(feeData, null, 2));
        console.log("✅ isConfigExecutor written to fee.json");
    }

    if (isWhitelisted) {
        // 更新 router.json
        const routerData = fs.existsSync(dexConfigPath) ? JSON.parse(fs.readFileSync(dexConfigPath, "utf8")) : {};
        routerData[chainId.toString()].isConfigExecutor = true;
        fs.writeFileSync(dexConfigPath, JSON.stringify(routerData, null, 2));
        console.log("✅ isConfigExecutor written to router.json");
    }

    // config AIExecutor 
    await aiExecutor.addDexRouter('uni',UniSwap.target)
    console.log("✅ AIExecutor added Dex Router:", UniSwap.target);
    const dexRouter = await aiExecutor.getRouterByDex('uni');
    console.log("✅ AIExecutor Dex Router:", dexRouter);

    await saveAiExecutorConfig(Number(chainId), aiExecutor.target);
}

async function updateAiExecutor() {
    const network = await ethers.provider.getNetwork();
    const chainId = network.chainId;
    console.log("🌐 Network ChainId:", chainId)
    if (!fs.existsSync(aiExecutorConfigPath)) {
        throw new Error(`❌ AiExecutor config file not found: ${aiExecutorConfigPath}`) ;
    }
    const aiExecutorConfig = JSON.parse(fs.readFileSync(aiExecutorConfigPath, "utf-8"));
    const aiExecutor = aiExecutorConfig[Number(chainId).toString()];
    if (!aiExecutor) {
        throw new Error(`❌ AiExecutor not found for chainId: ${chainId}`);
    }

    console.log("✅ AiExecutor Address:", aiExecutor.address);
    const AIExecutor = await ethers.getContractFactory("AiExecutor");
    const tx = await upgrades.upgradeProxy(aiExecutor.address, AIExecutor);
    await tx.waitForDeployment();
    console.log(`✅ AiExecutor upgraded at proxy address: ${tx.target}`);
}

updateAiExecutor().catch((error) => {
    console.error(error);
    process.exit(1);
});
