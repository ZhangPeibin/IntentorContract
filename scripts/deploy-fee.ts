import { ethers, upgrades } from "hardhat";
import fs from "fs";
import path from "path";



async function main() {
  const [deployer] = await ethers.getSigners();
  const { chainId } = await ethers.provider.getNetwork();

  console.log(`📡 Deploying Fee to chainId: ${chainId}`);
  console.log("👤 Deployer:", deployer.address);

  const Fee = await ethers.getContractFactory("Fee");
  const fee = await upgrades.deployProxy(
    Fee,
    [deployer.address, deployer.address],
    { initializer: "__Fee_init" }
  );
  await fee.waitForDeployment();

  const feeAddress = await fee.getAddress();
  console.log("✅ Fee deployed to:", feeAddress);

  // 保存到 config/fee.json 里，按 chainId 存储
  const configDir = path.join(__dirname, "../config");
  const configPath = path.join(configDir, "fee.json");

  fs.mkdirSync(configDir, { recursive: true });

  let config: Record<string, { fee: string }> = {};
  if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
  }

  config[chainId.toString()] = { fee: feeAddress };

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log(`📄 Fee address saved under chainId ${chainId} at: ${configPath}`);

}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});
