import { ethers, network, run, tenderly, upgrades } from "hardhat";
import {
  getImplementationAddress,
  getImplementationAddressFromBeacon,
} from "@openzeppelin/upgrades-core";

export async function deployAndVerify(contractName: string, args: any[]) {
  const Contract = await ethers.getContractFactory(contractName);

  console.log('Deploying', contractName);
  let contract = await Contract.deploy(...args);
  console.log(`${contractName} deployed to: ${contract.address}`);

  contract = await contract.deployed();
  console.log("Done");
  

  console.log("Verifying contract on Tenderly...", contractName, contract.address);

  await tenderly.verify({
    name: contractName,
    address: contract.address,
  });

  /*

  const networkName = network.name;

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
  return contract;
}


export async function deployTransparentUpgradeableProxy(contractName: string, args: any[]): Promise<any> {
  console.log(
    "\n---------------\n🖖🏽[ethers] Deploying TransparentUpgradeableProxy with VotingLogic as implementation on Tenderly.",
  );

  const VotingLogic = await ethers.getContractFactory(contractName);
  let proxyContract = await upgrades.deployProxy(VotingLogic);
  proxyContract = await proxyContract.deployed();

  const proxyAddress = proxyContract.address;

  console.log("VotingLogic proxy deployed to:", proxyAddress);
  console.log(
    "VotingLogic impl deployed to:",
    await getImplementationAddress(ethers.provider, proxyAddress),
  );

  return proxyContract;
}