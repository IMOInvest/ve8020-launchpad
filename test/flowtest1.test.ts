import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  Signer,
  ContractFactory,
  ContractTransaction,
  BigNumber,
  utils,
  constants,
  ContractReceipt,
} from "ethers";

import {
  RewardDistributor,
  // @ts-ignore
  Launchpad, VotingEscrow,
  TestToken,
  BPTToken,
  SmartWalletWhitelist,
  SmartWalletChecker,
  LensReward,
  RewardFaucet,
  BalancerToken,
  AuraToken,
  BalancerMinter,
} from "../typechain-types";

let owner: Signer;
let creator: Signer;
let user1: Signer;
let user2: Signer;
let user3: Signer;

let ownerAddress: string;
let creatorAddress: string;
let user1Address: string;
let user2Address: string;
let user3Address: string;

let user1Amount: BigNumber;
let user2Amount: BigNumber;
let totalRewardAmount: BigNumber;


let erc20Factory: ContractFactory;
let rewardToken: TestToken;

let bptFactory: ContractFactory;
let bptToken: BPTToken;

let rdFactory: ContractFactory;
let rewardDistributorImpl: RewardDistributor;
let veFactory: ContractFactory;
let votingEscrowImpl: VotingEscrow;
let rewardFaucetFactory: ContractFactory;
let rewardFaucetImpl: RewardFaucet;

let launchpadFactory: ContractFactory;
let launchpad: Launchpad;

let lens: LensReward;

let smartWalletChecker: SmartWalletWhitelist;
let smartCheckerAllower: SmartWalletChecker;

let balToken: BalancerToken;
let auraToken: AuraToken;
let balMinter: BalancerMinter;

let DAY: number = 60 * 60 * 24;
let WEEK: number = 60 * 60 * 24 * 7;


describe("Launchpad flow test", function () {

  before(async () => {
    [owner, creator, user1, user2, user3] = await ethers.getSigners();
    [ownerAddress, creatorAddress, user1Address, user2Address, user3Address] = await Promise.all([
      owner.getAddress(),
      creator.getAddress(),
      user1.getAddress(),
      user2.getAddress(),
      user3.getAddress(),
    ]);

    erc20Factory = await ethers.getContractFactory('TestToken');
    rewardToken = (await erc20Factory.deploy()) as TestToken;

    bptFactory = await ethers.getContractFactory('BPTToken');
    bptToken = (await bptFactory.deploy()) as BPTToken;

    veFactory = await ethers.getContractFactory('VotingEscrow');
    votingEscrowImpl = (await veFactory.deploy()) as VotingEscrow;

    rdFactory = await ethers.getContractFactory('RewardDistributor');
    rewardDistributorImpl = (await rdFactory.deploy()) as RewardDistributor;

    rewardFaucetFactory = await ethers.getContractFactory('RewardFaucet');
    rewardFaucetImpl = (await rewardFaucetFactory.deploy()) as RewardFaucet;

    const smartCheckerFactory = await ethers.getContractFactory('SmartWalletWhitelist');
    smartWalletChecker = (await smartCheckerFactory.deploy(creatorAddress)) as SmartWalletWhitelist;

    const smartCheckerAllowerFactory = await ethers.getContractFactory('SmartWalletChecker');
    smartCheckerAllower = (await smartCheckerAllowerFactory.deploy()) as SmartWalletChecker;

    const balFactory = await ethers.getContractFactory('BalancerToken');
    balToken = (await balFactory.deploy()) as BalancerToken;

    
    const auraFactory = await ethers.getContractFactory('AuraToken');
    auraToken = (await auraFactory.deploy()) as BalancerToken;

    const balMinterFactory = await ethers.getContractFactory('BalancerMinter');
    balMinter = (await balMinterFactory.deploy(balToken.address)) as BalancerMinter;

    const lensFactory = await ethers.getContractFactory('LensReward');
    lens = (await lensFactory.deploy()) as LensReward;

    totalRewardAmount = utils.parseEther("10000")
    await rewardToken.mint(creatorAddress, totalRewardAmount);
    
    user1Amount = utils.parseEther('2000');
    user2Amount = utils.parseEther('1000');
    await bptToken.mint(user1Address, user1Amount);
    await bptToken.mint(user2Address, user2Amount);
  });

  describe('Initial states', function() {
    it('Should mint initial token balances', async () => {

      expect(await rewardToken.balanceOf(creatorAddress)).to.equal(totalRewardAmount);
      expect(await bptToken.balanceOf(user1Address)).to.equal(user1Amount);
      expect(await bptToken.balanceOf(user2Address)).to.equal(user2Amount);
    });

    it('Should deploy empty VE implementation', async () => {
      const name = await votingEscrowImpl.name();
      const symbol = await votingEscrowImpl.symbol();
      const decimals = await votingEscrowImpl.decimals();
      const someValue = await votingEscrowImpl.get_last_user_slope(user1Address);
      const isInitialized = await votingEscrowImpl.is_initialized();
      expect(name).to.equal('');
      expect(symbol).to.equal('');
      expect(decimals).to.equal(0);
      expect(someValue).to.equal(0);
      expect(isInitialized).to.equal(false);
    });

    it('Should deploy empty RewardDistributor implementation', async () => {
      const ve = await rewardDistributorImpl.getVotingEscrow();
      const timeCursor = await rewardDistributorImpl.getTimeCursor();    
      const isInitialized = await rewardDistributorImpl.isInitialized();
      expect(ve).to.equal(constants.AddressZero);
      expect(timeCursor).to.equal(0);
      expect(isInitialized).to.equal(false);
    });

  });

  describe('With initialized implementations', function () {
    before(async() => {
      let maxLockTime: number = 60 * 60 * 24 * 7; // WEEK
      await votingEscrowImpl.initialize(
        bptToken.address,
        'initName',
        'initSymbol',
        user2Address,
        constants.AddressZero,
        constants.AddressZero,
        maxLockTime,
        constants.AddressZero,
        constants.AddressZero,
        constants.AddressZero,
        constants.AddressZero,
        false,
        constants.AddressZero,
      );

      const startTime = (await time.latest()) + WEEK * 3;
      await rewardDistributorImpl.initialize(
        votingEscrowImpl.address,
        rewardFaucetImpl.address,
        startTime,
        user2Address
      );

      await rewardFaucetImpl.initialize(
        rewardDistributorImpl.address
      );
    });

    it('Should return values of VE implementation', async () => {
      expect(await votingEscrowImpl.name()).to.equal('initName');
    });

    it('Should return values of RD implementation', async () => {
      expect(await rewardDistributorImpl.getVotingEscrow())
        .to.equal(votingEscrowImpl.address);
    });
  });


  describe('Deploy Launchpad', function () {
    before(async () => {
      launchpadFactory = await ethers.getContractFactory('Launchpad');
      launchpad = (await launchpadFactory.deploy(
        votingEscrowImpl.address,
        rewardDistributorImpl.address,
        rewardFaucetImpl.address,
        balToken.address,
        auraToken.address,
        balMinter.address
        )) as Launchpad;
    });
    
    it('Should set correct VE implementation of launchpad', async () => {
      expect(await launchpad.votingEscrow())
        .to.equal(votingEscrowImpl.address);
    });

    it('Should set correct RD implementation of launchpad', async () => {
      expect(await launchpad.rewardDistributor())
        .to.equal(rewardDistributorImpl.address);
    });

    it('Should set correct balToken and BalancerMinter addresses', async () => {
      expect(await launchpad.balToken())
        .to.equal(balToken.address);

      expect(await launchpad.balMinter())
        .to.equal(balMinter.address);
    });
  });


  describe('Deploy VE system', function () {
    let veName = 'Lock system 1';
    let veSymbol = 'LS_1';
    let txResult: ContractTransaction;
    let txReceipt: ContractReceipt;

    let votingEscrow: VotingEscrow;
    let rewardDistributor: RewardDistributor;

    let rewardStartTime: number;
    let maxLockTime: number = DAY * 30; // 30 days

    before(async () => {
      rewardStartTime = (await time.latest()) + WEEK;

      txResult = await launchpad.connect(creator).deploy(
        bptToken.address,
        veName,
        veSymbol,
        maxLockTime,
        rewardStartTime,
        creatorAddress,
        creatorAddress,
        creatorAddress
      );
      txReceipt = await txResult.wait();
    });

    it('Should emit event on deployment', async () => {
      // @ts-ignore
      const event = txReceipt.events[0];
      // @ts-ignore
      expect(event.args.token).to.equal(bptToken.address);
      // @ts-ignore
      expect(event.args.admin).to.equal(creatorAddress);
      // @ts-ignore
      expect(event.args.votingEscrow)
        .to.not.equal(constants.AddressZero);
      // @ts-ignore
      expect(event.args.rewardDistributor)
        .to.not.equal(constants.AddressZero);
    });

    describe('Deployed system test', function () {
      before(async() => {
        // @ts-ignore
        const votingEscrowAdr = txReceipt.events[0].args.votingEscrow;
        // @ts-ignore
        const rewardDistributorAdr = txReceipt.events[0].args.rewardDistributor;

        votingEscrow = await ethers.getContractAt(
          'VotingEscrow',
          votingEscrowAdr
        );
        rewardDistributor = await ethers.getContractAt(
          'RewardDistributor',
          rewardDistributorAdr
        );
      })

      it('Should return correct initial states for VotingEscrow', async () => {
        expect(await votingEscrow.name()).to.equal(veName);
        expect(await votingEscrow.symbol()).to.equal(veSymbol);

        expect(await votingEscrow.decimals())
          .to.equal(await bptToken.decimals());

        expect(await votingEscrow.token())
          .to.equal(bptToken.address);
      });

      it('Should return BAL properties of VotingEscrow', async () => {
        expect(await votingEscrow.balMinter())
          .to.equal(balMinter.address);

        expect(await votingEscrow.balToken())
          .to.equal(balToken.address);

        expect(await votingEscrow.rewardReceiver())
          .to.equal(creatorAddress);

        expect(await votingEscrow.rewardReceiverChangeable())
          .to.equal(true);
      });

      it('Should return non-zero initial point_history', async () => {
        const firstPH = await votingEscrow.point_history(0);
        expect(firstPH.blk).to.be.gt(3);
        expect(firstPH.ts).to.be.gt(1000);
      });

      it('Should return correct admin of the VotingEscrow', async () => {
        expect(await votingEscrow.admin()).to.equal(creatorAddress);
      });

      it('Should return correct MAXTIME of the lock of the VotingEscrow', async () => {
        expect(await votingEscrow.MAXTIME()).to.equal(maxLockTime);
      });

      it(`Shouldn't allow to initialize VotingEscrow again`, async () => {
        await expect(votingEscrow.initialize(
          bptToken.address,
          'newNameFail',
          'newSymbolFail',
          creatorAddress,
          constants.AddressZero,
          constants.AddressZero,
          maxLockTime,
          balToken.address,
          auraToken.address,
          balMinter.address,
          creatorAddress,
          true,
          rewardDistributor.address
        ))
          .to.be.revertedWith('only once');
      });

      it('Should return correct of the VotingEscrow for the rewardDistributor', async () => {
        expect(await rewardDistributor.getVotingEscrow())
          .to.equal(votingEscrow.address);
      });

      it('Should return non-zero timeCursor of the VotingEscrow', async () => {
        expect(await rewardDistributor.getTimeCursor())
          .to.be.gt(await time.latest());
      });

      describe('Users make locks (deposit)', function () {
        let createLockTime: number;

        before(async() => {
          // approvals before deposit
          await bptToken.connect(user1).approve(votingEscrow.address, constants.MaxUint256);
          await bptToken.connect(user2).approve(votingEscrow.address, constants.MaxUint256);

          // lock-deposit
          createLockTime = await time.latest();
          await votingEscrow.connect(user1).create_lock(user1Amount, createLockTime + WEEK * 2);
          await votingEscrow.connect(user2).create_lock(user2Amount, createLockTime + WEEK * 2);

        });

        it('Should return zero balance after deposit', async () => {
          expect(await bptToken.balanceOf(user1Address)).to.equal(constants.Zero);
          expect(await bptToken.balanceOf(user2Address)).to.equal(constants.Zero);
        });

        it('Should increase votingEscrow balance', async () => {
          expect(await bptToken.balanceOf(votingEscrow.address))
            .to.equal(user1Amount.add(user2Amount));
        })
      });

      describe('BAL rewards for admin', function () { 
        let adminBalanceBefore: BigNumber;
        let adminBalanceAfter: BigNumber;

        before(async() => {
          adminBalanceBefore = await balToken.balanceOf(creatorAddress);
          await votingEscrow.connect(user2).claimExternalRewards();
        });

        it('Should increase admin BAL balance after claimnig extarnal rewards', async () => {
          adminBalanceAfter = await balToken.balanceOf(creatorAddress);
          expect(adminBalanceBefore).to.equal(constants.Zero);

          expect(adminBalanceAfter).to.be.gt(adminBalanceBefore.add(1));
        });

       });

      describe('Adding reward tokens', function () {
        let startRewardTime: number;

        before(async() => {
          const depositAmount = totalRewardAmount;

          await rewardToken.connect(creator)
            .approve(rewardDistributor.address, constants.MaxUint256);

          await rewardDistributor.connect(creator)
            .addAllowedRewardTokens([rewardToken.address, balToken.address]);
          
          startRewardTime = (await rewardDistributor.getTimeCursor()).toNumber();
          await time.increaseTo(startRewardTime);

          await rewardDistributor.connect(creator)
            .depositToken(rewardToken.address, totalRewardAmount);
        });

        it('Should be able to deposit rewards into rewardDistributor', async () => {

          expect(await rewardToken.balanceOf(rewardDistributor.address))
            .to.equal(totalRewardAmount);
        })

        describe('Check available rewards after first WEEK past', function () {
          before(async () => {
            await time.increase(WEEK);
          });

          it('Should calculate correct claimable amounts of reward', async () => {
            let rewards = await lens.callStatic.getUserClaimableReward(rewardDistributor.address, user1Address, rewardToken.address)
            
            const user1rewards = (
              await lens.callStatic.getUserClaimableReward(
                rewardDistributor.address,
                user1Address,
                rewardToken.address
                )
              ).claimableAmount;
            const user2rewards = (
              await lens.callStatic.getUserClaimableReward(
                rewardDistributor.address,
                user2Address,
                rewardToken.address
                )
              ).claimableAmount

            // add 1 due to rounding
            expect(user1rewards.add(user2rewards).add(constants.One)).to.equal(totalRewardAmount);
          });

          describe('Rewards claiming', function () {
            let user1RewardBefore: BigNumber;
            let user2RewardBefore: BigNumber;

            before(async () => {
              user1RewardBefore = await rewardToken.balanceOf(user1Address);
              user2RewardBefore = await rewardToken.balanceOf(user2Address);

              await rewardDistributor.connect(user1)
                .claimToken(user1Address, rewardToken.address);
              await rewardDistributor.connect(user2)
                .claimToken(user2Address, rewardToken.address);              
            });

            it('Should increase reward balance after claim', async () => {
              const user1RewardAfter = await rewardToken.balanceOf(user1Address);
              const user2RewardAfter = await rewardToken.balanceOf(user2Address);
              expect(user1RewardAfter).to.be.gt(user1RewardBefore).to.be.gt(constants.Two);
              expect(user2RewardAfter).to.be.gt(user2RewardBefore).to.be.gt(constants.Two);

              expect(user1RewardAfter.add(user2RewardAfter).add(constants.One)).to.equal(totalRewardAmount);
            });

            it('Should decrease RewardDustributor balance after claim', async () => {
              const rdBalance = await rewardToken.balanceOf(rewardDistributor.address);

              expect(rdBalance).to.be.lte(constants.One);
            });
          });
        });
      });
    });
  });
});
