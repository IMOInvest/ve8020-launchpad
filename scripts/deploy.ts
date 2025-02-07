import { ethers, tenderly } from "hardhat";
import chalk from "chalk";

// Modified deployAndVerify function
async function deployAndVerify(contractName: string, args: any[]) {
  console.log(`Deploying ${contractName}...`);
  
  const Contract = await ethers.getContractFactory(contractName);
  let contract = await Contract.deploy(...args);
  
  // Wait for deployment - required for Tenderly verification
  contract = await contract.deployed();

  const address = await contract.address;
  
  console.log(`${contractName} deployed to:`, address);

  console.log('verification automatique :', process.env.TENDERLY_AUTOMATIC_VERIFICATION);

  return contract;
}
  

async function main() {
  const [owner] = await ethers.getSigners();
  console.log('Deployer address:', owner.address);

  // Deploy implementations
  const votingEscrowImpl = await deployAndVerify('VotingEscrow', []);
  const rewardDistributorImpl = await deployAndVerify('RewardDistributor', []);
  const rewardFaucetImpl = await deployAndVerify('RewardFaucet', []);

  const balToken = "0x4158734d47fc9692176b5085e0f52ee0da5d47f1";
  const balMinter = "0x0c5538098EBe88175078972F514C9e101D325D4F";
  const auraToken = '0x1509706a6c66ca549ff0cb464de88231ddbe213b';
  
  // Deploy launchpad
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
  );

  console.log(chalk.green('\nDeployment Summary:'));
  console.log('VotingEscrow Implementation:', votingEscrowImpl.address);
  console.log('RewardDistributor Implementation:', rewardDistributorImpl.address);
  console.log('RewardFaucet Implementation:', rewardFaucetImpl.address);
  console.log('Launchpad:', launchpad.address);

  // Generate constructor arguments for manual verification if needed
  
  const abi = [
    'constructor(address,address,address,address,address,address)',
  ];
  const contract = new ethers.utils.Interface(abi);
  const encodedArguments = contract.encodeDeploy([
    votingEscrowImpl.address,
    rewardDistributorImpl.address,
    rewardFaucetImpl.address,
    balToken,
    auraToken,
    balMinter
  ]);

  console.log(
    chalk.green.bold('\n❗️ Constructor Arguments (ABI-encoded) for Launchpad:'),
  );
  console.log(encodedArguments.slice(2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
