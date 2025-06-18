import { ethers, upgrades } from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  const configPath = path.join(__dirname, "../config/fee.json");

  if (!fs.existsSync(configPath)) {
    throw new Error("fee.json not found. Please deploy Fee contract first.");
  }

  const { fee } = JSON.parse(fs.readFileSync(configPath, "utf-8"));
  if (!fee || !ethers.isAddress(fee)) {
    throw new Error("Invalid Fee contract address in fee.json.");
  }

  console.log("Upgrading Fee contract at:", fee);

  const Fee = await ethers.getContractFactory("Fee");
  const upgraded = await upgrades.upgradeProxy(fee, Fee);
  await upgraded.waitForDeployment();

  const newAddress = await upgraded.getAddress();
  console.log("✅ Fee contract upgraded successfully:", newAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
