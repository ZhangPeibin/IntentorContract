import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const PRIVATE_KEY = vars.get('TEST_PK')
const config: HardhatUserConfig = {
  solidity: "0.8.28",
   mocha: {
    timeout: 100000000
  },
  networks: {
    hardhat: {
  
    },
    bsc: {
      url: 'https://binance.llamarpc.com',
      accounts: [PRIVATE_KEY],
    },
  },
};

export default config;
