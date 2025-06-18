import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";

const configPath = path.resolve(__dirname, "../config/router.json");

// 不同链的预设配置
const chainConfigs: Record<number, { name: string; router: string; wbnb: string }> = {
  56: {
    name: "bsc",
    router: "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2",
    wbnb: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
  },
  31337: {
    name: "localhost",
    router: "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2",
    wbnb: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
  },
  // 可以继续添加更多链
};

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await deployer.provider?.getNetwork();
  const chainId = Number(network?.chainId);

  if (!chainId || !(chainId in chainConfigs)) {
    throw new Error(`❌ Unsupported or unknown chain ID: ${chainId}`);
  }

  const { name, router, wbnb } = chainConfigs[chainId];

  console.log("👤 Deployer:", deployer.address);
  console.log("🔗 Chain:", name, "Chain ID:", chainId);
  console.log("🔁 Router:", router);
  console.log("💧 WBNB:", wbnb);

  const UniswapFactory = await ethers.getContractFactory("Uniswap");
  const uniswap = await UniswapFactory.deploy(router, wbnb);
  await uniswap.waitForDeployment();

  const deployedAddress = await uniswap.getAddress();
  console.log("🚀 Router contract deployed at:", deployedAddress);

  const newRecord = {
    chainId,
    network: name,
    address: deployedAddress,
    router,
    wbnb,
    deployedAt: new Date().toISOString(),
  };

  // 读取已有的 router.json 文件（如果存在）
  let configData: Record<number, any> = {};
  if (fs.existsSync(configPath)) {
    const raw = fs.readFileSync(configPath, "utf-8");
    configData = JSON.parse(raw);
  }

  // 更新当前链的记录
  configData[chainId] = newRecord;

  fs.mkdirSync(path.dirname(configPath), { recursive: true });
  fs.writeFileSync(configPath, JSON.stringify(configData, null, 2));

  console.log("✅ Saved config to:", configPath);
}

main().catch((err) => {
  console.error("❌ Deployment failed:", err);
  process.exit(1);
});
