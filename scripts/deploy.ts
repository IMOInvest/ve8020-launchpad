import chalk from "chalk";
import { ethers, network, run } from "hardhat";

export async function deployAndVerify(contractName: string, args: any[]) {
  const Contract = await ethers.getContractFactory(contractName);

  console.log('Deploying', contractName);
  let contract = await Contract.deploy(...args);

  contract = await contract.deployed();

  const contractAdress = await contract.address;
  console.log(`${contractName} deployed to: ${contractAdress}`);

  console.log("Done");

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
  return contract;
}

async function main() {
  const [owner] = await ethers.getSigners();
  console.log('Deployer address:', owner.address);

  // we need only implementations for the launchpad
  const votingEscrowImpl = await deployAndVerify('VotingEscrow', []);
  const rewardDistributorImpl = await deployAndVerify('RewardDistributor', []);
  const rewardFaucetImpl = await deployAndVerify('RewardFaucet', []);

  // @todo
  const balToken = "0x4158734d47fc9692176b5085e0f52ee0da5d47f1";
  const balMinter = "0x0c5538098EBe88175078972F514C9e101D325D4F";
  const auraToken = '0x1509706a6c66ca549ff0cb464de88231ddbe213b';
  
  // deploying launchpad
  const launchpad = await deployAndVerify(
    'Launchpad',
    [
      votingEscrowImpl.address,
      rewardDistributorImpl.address,
      rewardFaucetImpl.address,
      balToken,
      auraToken,
      balMinter
    ]
  )

  console.log('The VotingEscrow Implementation deployed at:', votingEscrowImpl.address);
  console.log('The RewardDistributor Implementation deployed at:', rewardDistributorImpl.address);
  console.log('The RewardFaucet Implementation deployed at:', rewardFaucetImpl.address);

  console.log('The Launchpad deployed at:', launchpad.address);

  const abi = [
    'constructor(address,address,address,address,address,address)',
  ];
  const contract = new ethers.utils.Interface(abi);
  const encodedArguments = contract.encodeDeploy(
    [
      votingEscrowImpl.address,
      rewardDistributorImpl.address,
      rewardFaucetImpl.address,
      balToken,
      auraToken,
      balMinter
    ]
  );

  console.log(
    chalk.green.bold('\n❗️ Use following Constructor Arguments (ABI-encoded) for Launchpad verification:'),
  );
  console.log(encodedArguments.slice(2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
