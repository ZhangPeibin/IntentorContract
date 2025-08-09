import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

const PRIVATE_KEY = vars.get('TEST_PK') || "0x0000000";
const config: HardhatUserConfig = {
  solidity: "0.8.28",

  mocha: {
    timeout: 100000000,
 
  },
  networks: {
    hardhat: {

    },
    bsc: {
      url: 'https://bsc.blockrazor.xyz',
      accounts: [PRIVATE_KEY],
    },
    
  },
};

export default config;
