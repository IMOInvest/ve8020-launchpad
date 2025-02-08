import { ethers, network, run } from "hardhat";
import "@tenderly/hardhat-tenderly";

require("dotenv").config();


export async function deployAndVerify(contractName: string, args: any[]) {
  const Contract = await ethers.getContractFactory(contractName);

  console.log('Deploying', contractName);
  let contract = await Contract.deploy(...args);

  contract = await contract.deployed();
  console.log(`${contractName} deployed to: ${contract.address}`);

  const networkName = network.name;
  /*

  if (networkName != "hardhat" && !['Launchpad', 'VotingEscrow'].includes(contractName)) {
    console.log(`Verifying contract ${contractName} ...`);
      try {
        await new Promise((resolve) => {
          console.log('Waiting for 5 seconds until chain is ready for verifying')
          setTimeout(resolve, 5000);
        });
        await run("verify:verify", {
              address: contract.address,
              constructorArguments: args,
          });
          console.log("Contract has been verified");
      } catch (error: any) {
          console.log("Failed in plugin", error.pluginName);
          console.log("Error name", error.name);
          console.log("Error message", error.message);
      }
    }
  */
  deployAndVerify(contractName,args).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });


  return contract;
}
