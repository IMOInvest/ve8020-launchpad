## Frontend integration

### System creation and management
1) Create system using Launchpad contract.
```
function deploy(
  address tokenBptAddr,
  string memory name,
  string memory symbol,
  uint256 maxLockTime,
  uint256 rewardDistributorStartTime
)
```
**Parameters details and constraints:**  
`tokenBptAddr` - token or liquidity-token provided by creator  
`name` - any name provided by creator  
`symbol` - any symbol provided by creator  
`maxLockTime` - time in seconds. **Must be >= `604800` (7 days)**  
`rewardDistributorStartTime` - unix timestamp. **Must be >= unix-timestamp of next Thursday 00:00**  

After calling the `deploy()` function, contracts VotingEscrow and RewardDistributor will be created for the caller (admin). The addresses of these contracts can be obtained from the `VESystemCreated(address bptToken, address votingEscrow, address rewardDistributor, address admin)` event of the deploy() function. 

2) After creation admin (creator) must add allowed token for the reward distribution.
To do that use following function of the RewardDistributor constract:  
```
function addAllowedRewardTokens(address[] calldata tokens);
```

3) To provide rewards into RewardDistributor constract any user can use one of the following functions:  
```
function depositToken(address token, uint256 amount);  
function depositTokens(address[] calldata tokens, uint256[] calldata amounts);  
```  
**Parameters details and constraints:**  
`token` - token address, that already added to allowed list (see point 2),
`amount` - amount for token  
Note: 
  - tokens can be added to the weekly distribution no earlier than `rewardDistributorStartTime`.
  - Every Thursday at 00:00 a new week of reward distributions begins.

4) The Subgraph can be used to track the history of awards added each week. 
```
@todo
```



### Users interaction

#### VotingEscrow  

1) VotingEscrow metadata:
```
function name() external view returns (string memory);
function symbol() external view returns (string memory);
function token() external view returns (address);
function decimals() external view returns (uint256);
```
Returns:
- name of the VotingEscrow contract,  
- symbol of the VotingEscrow contract,  
- address of the token that can be locked,  
- decimals of the token that can be locked,  

2) [Create new lock](../2_VotingEscrow.md/#create_lock)  
Creates new lock for a user.  

3) [Increase lock amount](../2_VotingEscrow.md/#increase_amount)  
Increases lock amount to increase (voting) power of lock.  

4) [Increase unlock time](../2_VotingEscrow.md/#increase_unlock_time)
Increases lock unlock time to increase (voting) power of lock.  

5) To get information when the user's lock amount and lock deadline:   
```
function locked(address account) external view returns (uint256 amount, uint256 deadline);  
```
Returns:  
- `amount` of locked tokens;  
- `unix-times` of the lock end.  

5) [Withdraw tokens when lock is finished](../2_VotingEscrow.md/#withdraw)
Withdraws tokens to user.  

6) Each VotingEscrow contract has lock-MaxTime value defined in seconds. To check lock-maxtime:  
```
function MAXTIME() external view returns (uint256);
```  
Returns Maxtime value in seconds for current VotingEscrow contract.




#### RewardDistributor
1) [Add allowed token for the distribution](../3_RewardDistributor.md/#addallowedrewardtokens)  

2) Get list of allowed tokens for a distribution:  
```
function getAllowedRewardTokens() external view returns (address[] memory)
```  
Returns allowed for reward distribution tokens list.  


3) [Deposit tokens for the week distribution](../3_RewardDistributor.md/#deposittoken)  

4) Use LensReward contracts to check user's pending rewards:  
```
struct ClaimableRewards {
  address token;
  uint256 claimableAmount;
}

LensReward.getUserClaimableRewardsAll(
  address rewardDistributor,
  address user,
  address[] calldata allowedRewardTokenList
) external view returns (ClaimableRewards[] memory)
```
Parameters:  
`rewardDistributor` - The address of the RewardDistributor contract  
`user` - The user's address to check pending rewards on  
`allowedRewardTokenList` - The array of available reward tokens to check rewards  

Returns an array with objects with ClaimableRewards data.  

5) Rewards claiming
[Claim one token](../3_RewardDistributor.md/#claimtoken)  
[Claim multiple tokens](../3_RewardDistributor.md/#claimtokens)  

