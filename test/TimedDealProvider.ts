import { LockDealProvider } from '../typechain-types';
import { TimedDealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { MockProvider } from '../typechain-types';
import { MockVaultManager } from '../typechain-types';
import { deployed, token, BUSD, MAX_RATIO } from './helper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Timed Deal Provider', function () {
  let timedDealProvider: TimedDealProvider;
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let lockDealNFT: LockDealNFT;
  let mockProvider: MockProvider;
  let mockVaultManager: MockVaultManager;
  let halfTime: number;
  let poolId: number;
  let vaultId: BigNumber;
  let addresses: string[];
  let params: [number, number, number];
  let receiver: SignerWithAddress;
  let newOwner: SignerWithAddress;
  let startTime: number, finishTime: number;
  const amount = 100000;
  const ratio = MAX_RATIO.div(2); // half of the amount

  before(async () => {
    [receiver, newOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    timedDealProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
    mockProvider = await deployed('MockProvider', lockDealNFT.address, timedDealProvider.address);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedDealProvider.address, true);
    await lockDealNFT.setApprovedProvider(mockProvider.address, true);
  });

  beforeEach(async () => {
    const ONE_DAY = 86400;
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
    params = [amount, startTime, finishTime];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    addresses = [receiver.address, token];
    await timedDealProvider.createNewPool(addresses, params);
    vaultId = await mockVaultManager.Id();
    halfTime = (finishTime - startTime) / 2;
  });

  it('should return provider name', async () => {
    expect(await timedDealProvider.name()).to.equal('TimedDealProvider');
  });

  it('should get timed provider data after creation', async () => {
    const poolData = await lockDealNFT.getData(poolId);
    const params = [amount, startTime, finishTime, amount];
    expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
  });

  it('should get user data by one token', async () => {
    const params = [amount, startTime, finishTime, amount];
    await timedDealProvider.createNewPool(addresses, params);
    const poolData = await lockDealNFT.getUserDataByTokens(receiver.address, [token], poolId, poolId);
    expect(poolData[0]).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
    expect(poolData.length).to.equal(1);
  });

  it('should get user data with two tokens', async () => {
    const params = [amount, startTime, finishTime, amount];
    const from = (await lockDealNFT.totalSupply()).toNumber();
    await timedDealProvider.createNewPool(addresses, params);
    const vaultId = await mockVaultManager.Id();
    addresses[1] = BUSD;
    await timedDealProvider.createNewPool(addresses, params);
    const to = from + 1;
    const poolData = await lockDealNFT.getUserDataByTokens(receiver.address, [token, BUSD], from, to);
    expect(poolData[0]).to.deep.equal([timedDealProvider.address, from, vaultId, receiver.address, token, params]);
    expect(poolData[1]).to.deep.equal([timedDealProvider.address, to, vaultId.add(1), receiver.address, BUSD, params]);
    expect(poolData.length).to.equal(2);
  });

  it('should get user data with three tokens', async () => {
    const params = [amount, startTime, finishTime, amount];
    const USDT = '0x55d398326f99059ff775485246999027b3197955';
    const from = (await lockDealNFT.totalSupply()).toNumber();
    await timedDealProvider.createNewPool(addresses, params);
    const vaultId = await mockVaultManager.Id();
    addresses[1] = BUSD;
    await timedDealProvider.createNewPool(addresses, params);
    addresses[1] = USDT;
    await timedDealProvider.createNewPool(addresses, params);
    const to = from + 2;
    const poolData = await lockDealNFT.getUserDataByTokens(receiver.address, [token, BUSD, USDT], from, to);
    expect(poolData[0]).to.deep.equal([timedDealProvider.address, from, vaultId, receiver.address, token, params]);
    expect(poolData[1]).to.deep.equal([
      timedDealProvider.address,
      from + 1,
      vaultId.add(1),
      receiver.address,
      BUSD,
      params,
    ]);
    expect(poolData[2]).to.deep.equal([timedDealProvider.address, to, vaultId.add(2), receiver.address, USDT, params]);
    expect(poolData.length).to.equal(3);
  });

  it('should check cascade UpdateParams event', async () => {
    const tx = await timedDealProvider.createNewPool(addresses, params);
    await tx.wait();
    const event = await dealProvider.queryFilter(dealProvider.filters.UpdateParams());
    const data = event[event.length - 1].args;
    expect(data.poolId).to.equal(poolId + 1);
    expect(data.params[0]).to.equal(amount);
  });

  it('should revert zero owner address', async () => {
    addresses[1] = constants.AddressZero;
    await expect(timedDealProvider.createNewPool(addresses, params)).to.be.revertedWith('Zero Address is not allowed');
  });

  it('should revert zero token address', async () => {
    addresses[0] = constants.AddressZero;
    await expect(timedDealProvider.createNewPool(addresses, params)).to.be.revertedWith('Zero Address is not allowed');
  });

  describe('Timed Split Amount', () => {
    it('should check data in old pool after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount / 2, startTime, finishTime, amount / 2];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
    });

    it('should check data in new pool after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount / 2, startTime, finishTime, amount / 2];
      const poolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId + 1, vaultId, newOwner.address, token, params]);
    });

    it('should check event data after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      const tx = await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      await tx.wait();
      const events = await lockDealNFT.queryFilter(lockDealNFT.filters.PoolSplit());
      expect(events[events.length - 1].args.poolId).to.equal(poolId);
      expect(events[events.length - 1].args.newPoolId).to.equal(poolId + 1);
      expect(events[events.length - 1].args.owner).to.equal(receiver.address);
      expect(events[events.length - 1].args.newOwner).to.equal(newOwner.address);
      expect(events[events.length - 1].args.splitLeftAmount).to.equal(amount / 2);
      expect(events[events.length - 1].args.newSplitLeftAmount).to.equal(amount / 2);
    });

    it('should withdraw 10% and then split 50% tokens', async () => {
      await time.setNextBlockTimestamp(startTime + halfTime / 5); // 10% of time
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      // split 50% of tokens
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const poolData = await lockDealNFT.getData(poolId);
      const newPoolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData.params[3].add(newPoolData.params[3])).to.equal(amount);
      expect(poolData.params[0].add(newPoolData.params[0])).to.equal(amount - amount / 10);
    });

    it('should withdraw 25% and then split 25% tokens', async () => {
      await time.setNextBlockTimestamp(startTime + halfTime / 2); // 25% of time
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      // split 25% of tokens
      const ratio = MAX_RATIO.div(4);
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const poolData = await lockDealNFT.getData(poolId);
      const newPoolData = await lockDealNFT.getData(poolId + 1);

      expect(poolData.params[3].add(newPoolData.params[3])).to.equal(amount);
      expect(poolData.params[0].add(newPoolData.params[0])).to.equal(amount - amount / 4);
    });
  });

  describe('Timed Withdraw', () => {
    it('getWithdrawableAmount should return zero before startTime', async () => {
      expect(await timedDealProvider.getWithdrawableAmount(poolId)).to.equal(0);
    });

    it('should withdraw 25% tokens', async () => {
      await time.setNextBlockTimestamp(startTime + halfTime / 2);

      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const params = [amount - amount / 4, startTime, finishTime, amount];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
    });

    it('should withdraw half tokens', async () => {
      await time.setNextBlockTimestamp(startTime + halfTime);

      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const params = [amount / 2, startTime, finishTime, amount];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
    });

    it('should withdraw all tokens', async () => {
      await time.setNextBlockTimestamp(finishTime + 1);

      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const params = [0, startTime, finishTime, amount];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, lockDealNFT.address, token, params]);
    });
  });

  describe('test higher cascading providers', () => {
    beforeEach(async () => {
      poolId = (await lockDealNFT.totalSupply()).toNumber();
      await mockProvider.createNewPool(addresses, params);
      vaultId = await mockVaultManager.Id();
      await time.setNextBlockTimestamp(startTime);
    });

    it('should register data', async () => {
      const poolData = await lockDealNFT.getData(poolId);
      const params = [amount, startTime, finishTime, amount];
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
    });

    it('should withdraw half tokens with higher mock provider', async () => {
      await mockProvider.withdraw(poolId, amount / 2);
      const poolData = await lockDealNFT.getData(poolId);
      const params = [amount / 2, startTime, finishTime, amount];
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
    });

    it('should withdraw all tokens with higher mock provider', async () => {
      await mockProvider.withdraw(poolId, amount);
      const poolData = await lockDealNFT.getData(poolId);
      const params = [0, startTime, finishTime, amount];
      expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
    });

    it("invalid provider can't change data", async () => {
      const invalidContract = await deployed<MockProvider>(
        'MockProvider',
        lockDealNFT.address,
        timedDealProvider.address,
      );
      await expect(invalidContract.createNewPool(addresses, params)).to.be.revertedWith('Contract not approved');
    });

    it("invalid provider can't withdraw", async () => {
      const invalidContract = await deployed<MockProvider>(
        'MockProvider',
        lockDealNFT.address,
        timedDealProvider.address,
      );
      await expect(invalidContract.withdraw(poolId, amount / 2)).to.be.revertedWith('invalid provider address');
    });
  });
});
