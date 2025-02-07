import { HardhatUserConfig } from "hardhat/config";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-vyper";
import "@nomicfoundation/hardhat-foundry";
import * as tdly from "@tenderly/hardhat-tenderly";



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
      url: "https://virtual.base.rpc.tenderly.co/e6bcbb6f-f37f-45db-bfe0-c85019847821",
      chainId: 8453,
      currency: "VETH"
    },
  },
  tenderly: {
    // https://docs.tenderly.co/account/projects/account-project-slug
    project: "imo",
    username: "hybr1d",
  },
};

export default hhconfig;
