import { ethers, network, run, tenderly, upgrades } from "hardhat";
import {
  getImplementationAddress,
  getImplementationAddressFromBeacon,
} from "@openzeppelin/upgrades-core";

function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export async function deployAndVerify(contractName: string, args: any[] = [], isProxy: boolean = false) {
  console.log("Deploying", contractName, "with args", args);
  const Contract = await ethers.getContractFactory(contractName);

  console.log("Got Contract", Contract);

  let contract;
  if (isProxy) {
    console.log(
      "\n---------------\n🖖🏽[ethers] Deploying TransparentUpgradeableProxy with VotingLogic as implementation on Tenderly."
    );

    contract = await upgrades.deployProxy(Contract, args);
    // await contract.deployed();
    await sleep(3000);

    const proxyAddress = contract.address;

    console.log("VotingLogic proxy deployed to:", proxyAddress);
    console.log(
      "VotingLogic impl deployed to:",
      await getImplementationAddress(ethers.provider, proxyAddress),
    );

    console.log("Verifying proxy contract on Tenderly...", proxyAddress);

    try {
      await tenderly.verify({
        name: contractName,
        address: proxyAddress,
      });
      console.log("Proxy contract verified on Tenderly");
    } catch (error) {
      console.error("Tenderly verification failed:", error);
    }

    return contract;
  } else {
    console.log('Deploying', contractName);
    contract = await Contract.deploy(...args);
    console.log(`${contractName} deployed to: ${contract.address}`);

    // await contract.deployed();
    await sleep(3000);
    console.log("Done");

    console.log("Verifying contract on Tenderly...", contractName, contract.address);

    try {
      await tenderly.verify({
        name: contractName,
        address: contract.address,
      });
      console.log("Contract verified on Tenderly");
    } catch (error) {
      console.error("Tenderly verification failed:", error);
    }

    return contract;
  }
}
