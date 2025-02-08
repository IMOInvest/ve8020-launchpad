import { HardhatUserConfig } from "hardhat/config";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-vyper";
import "@nomicfoundation/hardhat-foundry";

import "@tenderly/hardhat-tenderly";
/*
import "@nomiclabs/hardhat-ethers"
import "@nomicfoundation/hardhat-verify";
import * as dotenv from "dotenv";
*/


const config = require("./config.js");

const hhconfig: HardhatUserConfig = {
  
  solidity: {
    compilers: [
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ]
  },
  vyper: {
    compilers: [
      {
        version: "0.3.7",
      },
    ]
  },

  defaultNetwork: "tenderly",

  networks: {
    hardhat: {
      forking: {
        url: "https://polygon-mumbai-bor.publicnode.com",
        enabled: false,
      },
    },
    ethereumMainnet: {
      url: config.rpcUrl,
      accounts: config.mainnetAccounts,
    },
    sepolia: {
        url: config.rpcUrl,
        accounts: config.testnetAccounts,
    },
    bscMainnet: {
        url: config.rpcUrl,
        accounts: config.mainnetAccounts,
    },
    bscTestnet: {
        url: config.rpcUrl,
        accounts: config.testnetAccounts,
    },
    polygonMainnet: {
        url: config.rpcUrl,
        accounts: config.mainnetAccounts,
    },
    polygonTestnet: {
        url: config.rpcUrl,
        accounts: config.testnetAccounts,
    },
    baseTenderly : {
      url: config.rpcUrl,
      accounts: config.mainnetAccounts,
    },

   

  },

   
  tenderly : {
    project: 'Imo',
    username: 'hybr1d',
  },

  // docs: https://www.npmjs.com/package/@nomiclabs/hardhat-etherscan
  etherscan: {
    apiKey: {
      mainnet: config.apiKeyEtherscan,
      ropsten: config.apiKeyEtherscan,
      kovan: config.apiKeyEtherscan,
      rinkeby: config.apiKeyEtherscan,
      goerli: config.apiKeyEtherscan,

      bsc: config.apiKeyBscScan,
      bscTestnet: config.apiKeyBscScan,

      polygon: config.apiKeyPolygonScan,
      polygonMumbai: config.apiKeyPolygonScan,

      baseTenderly: config.apiKeyBaseTenderly,

      // to get all supported networks
      // npx hardhat verify --list-networks
    },
    customChains: [
      {
        network: "baseTenderly",
        chainId: 8453,
        urls: {
          apiURL: "https://virtual.base.rpc.tenderly.co/f16ba934-9d01-47c8-87c6-e1c8e35ef886/verify/etherscan",
          browserURL: "https://virtual.base.rpc.tenderly.co/f16ba934-9d01-47c8-87c6-e1c8e35ef886"
        }
      }
    ]
  },
};

export default hhconfig;
