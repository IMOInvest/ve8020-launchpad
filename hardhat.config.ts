import { HardhatUserConfig } from "hardhat/config";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-vyper";
import "@nomicfoundation/hardhat-foundry";
import "@tenderly/hardhat-tenderly";



const config = require("./config.js");

const { TENDERLY_PRIVATE_VERIFICATION, TENDERLY_AUTOMATIC_VERIFICATION } =
  process.env;



const privateVerification = TENDERLY_PRIVATE_VERIFICATION === "true";
const automaticVerifications = TENDERLY_AUTOMATIC_VERIFICATION === "true";

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

  defaultNetwork: "virtual_base",

  networks: {
    virtual_base: {
      url: "https://virtual.base.rpc.tenderly.co/f16ba934-9d01-47c8-87c6-e1c8e35ef886",
      chainId: 8453,
      currency: "VETH"
    },
  },
  tenderly: {
    // https://docs.tenderly.co/account/projects/account-project-slug
    project: "Imo",
    username: "hybr1d",
  },
};

export default hhconfig;
