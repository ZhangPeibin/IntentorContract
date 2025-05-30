import { ethers } from "ethers";
import axios from "axios";
import * as dotenv from "dotenv";
dotenv.config();

const VERIFY_API = process.env.VERIFY_API || 'http://localhost:3000/api/verify';

async function main() {
  const wallet = ethers.Wallet.createRandom();
  console.log("🧾 Wallet address:", wallet.address);

  const chainId = 56; 

  // 1. 获取 nonce + SIWE 签名消息模板
  const signInfoRes = await axios.get(`${VERIFY_API}/signinfo`, {
    params: {
      address: wallet.address,
      chain: chainId,
    },
  });

  const { nonce, siwe } = signInfoRes.data;
  console.log("🌀 Nonce:", nonce);
  console.log("📜 SIWE message:", siwe);

  // 2. 签名 SIWE 消息
  const signature = await wallet.signMessage(siwe);
  console.log("✍️ Signature:", signature);

  // 3. 发送到 verify 接口进行验证
  const verifyRes = await axios.post(`${VERIFY_API}`, {
    message: siwe,
    signature,
  });

  console.log("✅ Verify Response:", verifyRes.data);
  console.log("🔐 JWT Token:", verifyRes.data.token);
}

main().catch((err) => {
  console.error("❌ Error:", err);
  process.exit(1);
});
