# ve8020 Launchpad

Detailed instructions for each contract:  
[Launchpad](./docs/1_Launchpad.md)  
[VotingEscrow](./docs/2_VotingEscrow.md)  
[RewardDistributor](./docs/3_RewardDistributor.md)  
[RewardFaucet](./docs/4_RewardFaucet.md)  

Additional modules:  
[LensReward](./docs/misc_docs/LensReward.md)  
[SmartWalletWhitelist](./docs/misc_docs/SmartWalletWhitelist.md)  


In case of errors, visit this [troubleshooting section](./docs/misc_docs/Troubleshooting.md).


## Installation
Clone repo and run:  

```sh
npm i
```


## Deploy contracts
Create `config.js` file like provided `config.example.js` before deployment. Update necessary variables.  
To deploy VotingEscrow, RewardDistributor implementations and **Launchpad** contract run following command:  
```sh
npx hardhat run ./scripts/deploy.ts --network networkName

 pnpm exec hardhat run scripts/deploy.ts --network baseMainnet
```
Check list of available networks in the [hardhat.config.ts](./hardhat.config.ts) file.


### Testing
To run tests:  
```sh
npx hardhat test  

pnpm exec hardhat test

```

test deploy with launchpad:

```sh
cast call 0x6E8090214b0C44dB7206cb7D0a6533507a19163c "deploy(address,string,string,uint256,uint256)" 0xcCAC11368BDD522fc4DD23F98897712391ab1E00 "test2" "veRETH3" 604800 17400060005 --rpc-url https://g.w.lavanet.xyz:443/gateway/base/rpc-http/d3630392db153e71701cd89c262c116e --private-key 0x225f08b0a623e4797e27d60dc95c8cec6f485b6659c574a8615545233464dc93 --trace --debug
```

claim reward:

```sh
cast call 0xBA2287415914814a1AE78395c84c9eC5aE0fDbA5 "claimAuraRewards()" --rpc-url https://g.w.lavanet.xyz:443/gateway/base/rpc-http/d3630392db153e71701cd89c262c116e --private-key 0x225f08b0a623e4797e27d60dc95c8cec6f485b6659c574a8615545233464dc93 --trace
```