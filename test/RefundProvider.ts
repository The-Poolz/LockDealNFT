import { MockVaultManager } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { LockDealProvider } from '../typechain-types';
import { RefundProvider } from '../typechain-types';
import { TimedDealProvider } from '../typechain-types';
import { CollateralProvider } from '../typechain-types';
import { MockProvider } from '../typechain-types';
import { deployed, token, BUSD, MAX_RATIO } from './helper';
import { time, mine } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Bytes, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Refund Provider', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let mockProvider: MockProvider;
  let refundProvider: RefundProvider;
  let timedProvider: TimedDealProvider;
  let mockVaultManager: MockVaultManager;
  let collateralProvider: CollateralProvider;
  let halfTime: number;
  const rate = ethers.utils.parseUnits('0.1', 21);
  const mainCoinAmount = ethers.utils.parseEther('10');
  let lockDealNFT: LockDealNFT;
  let poolId: number;
  let vaultId: BigNumber;
  let receiver: SignerWithAddress;
  let projectOwner: SignerWithAddress;
  let addresses: string[];
  let params: [BigNumber, number, number, BigNumber, number];
  let startTime: number, finishTime: number;
  const name: string = 'RefundProvider';
  const timedName: string = 'TimedDealProvider';
  const collateralName: string = 'CollateralProvider';
  const tokenSignature: Bytes = ethers.utils.toUtf8Bytes('signature');
  const mainCoinsignature: Bytes = ethers.utils.toUtf8Bytes('signature');
  const amount = ethers.utils.parseEther('100');
  const halfAmount = amount.div(2);
  const ONE_DAY = 86400;
  const ratio = MAX_RATIO.div(2);

  before(async () => {
    [receiver, projectOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    timedProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
    collateralProvider = await deployed('CollateralProvider', lockDealNFT.address, dealProvider.address);
    refundProvider = await deployed('RefundProvider', lockDealNFT.address, collateralProvider.address);
    mockProvider = await deployed('MockProvider', lockDealNFT.address, refundProvider.address);
    await lockDealNFT.setApprovedContract(refundProvider.address, true);
    await lockDealNFT.setApprovedContract(lockProvider.address, true);
    await lockDealNFT.setApprovedContract(dealProvider.address, true);
    await lockDealNFT.setApprovedContract(timedProvider.address, true);
    await lockDealNFT.setApprovedContract(collateralProvider.address, true);
    await lockDealNFT.setApprovedContract(lockDealNFT.address, true);
    await lockDealNFT.setApprovedContract(mockProvider.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
    params = [amount, startTime, finishTime, mainCoinAmount, finishTime];
    addresses = [receiver.address, token, BUSD, timedProvider.address];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    await refundProvider
      .connect(projectOwner)
      .createNewRefundPool(addresses, params, tokenSignature, mainCoinsignature);
    vaultId = await mockVaultManager.Id();
    halfTime = (finishTime - startTime) / 2;
  });

  it('should return provider name', async () => {
    expect(await refundProvider.name()).to.equal('RefundProvider');
  });

  it('should return empty array if pool id is not refund provider', async () => {
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    await dealProvider.createNewPool(addresses, params, tokenSignature);
    expect(await refundProvider.getParams(poolId)).to.deep.equal([]);
  });

  describe('Pool Creation', async () => {
    it('should return refund pool data after creation', async () => {
      const poolData = await lockDealNFT.getData(poolId);
      const params = [amount, amount.mul(rate).div(MAX_RATIO)];
      expect(poolData).to.deep.equal([
        refundProvider.address,
        name,
        poolId,
        vaultId.sub(1),
        receiver.address,
        token,
        params,
      ]);
    });

    it('should return currect token pool data after creation', async () => {
      const poolData = await lockDealNFT.getData(poolId + 1);
      const params = [amount, startTime, finishTime, amount];

      expect(poolData).to.deep.equal([
        timedProvider.address,
        timedName,
        poolId + 1,
        vaultId.sub(1),
        refundProvider.address,
        token,
        params,
      ]);
    });

    it('should return currect collateral pool data after creation', async () => {
      const poolData = await lockDealNFT.getData(poolId + 2);
      const params = [mainCoinAmount, finishTime, MAX_RATIO.div(10)];
      expect(poolData).to.deep.equal([
        collateralProvider.address,
        collateralName,
        poolId + 2,
        vaultId,
        projectOwner.address,
        BUSD,
        params,
      ]);
    });

    it('should return currect main coin collector pool data after creation', async () => {
      const poolData = await lockDealNFT.getData(poolId + 3);
      const params = [0];
      expect(poolData).to.deep.equal([
        dealProvider.address,
        'DealProvider',
        poolId + 3,
        vaultId,
        collateralProvider.address,
        BUSD,
        params,
      ]);
    });

    it('should return currect token collector pool data after creation', async () => {
      const poolData = await lockDealNFT.getData(poolId + 4);
      const params = [0];
      expect(poolData).to.deep.equal([
        dealProvider.address,
        'DealProvider',
        poolId + 4,
        vaultId.sub(1),
        collateralProvider.address,
        token,
        params,
      ]);
    });

    it('should return currect main coin holder pool data after creation', async () => {
      const poolData = await lockDealNFT.getData(poolId + 5);
      const params = [mainCoinAmount];
      expect(poolData).to.deep.equal([
        dealProvider.address,
        'DealProvider',
        poolId + 5,
        vaultId,
        collateralProvider.address,
        BUSD,
        params,
      ]);
    });

    it('should revert invalid provider', async () => {
      addresses[3] = refundProvider.address;
      await expect(
        refundProvider.createNewRefundPool(addresses, params, tokenSignature, mainCoinsignature),
      ).to.be.revertedWith('invalid provider type');
    });

    it('should register new refund by other approved contract', async () => {
      await mockProvider.registerNewRefundPool(receiver.address, collateralProvider.address);
      poolId = (await lockDealNFT.totalSupply()).toNumber() - 3;
      const poolData = await lockDealNFT.getData(poolId);
      const params = [0, 0];
      expect(poolData).to.deep.equal([
        refundProvider.address,
        name,
        poolId,
        0,
        receiver.address,
        constants.AddressZero,
        params,
      ]);
    });

    it('should return full data from RefundProvider', async () => {
      const poolId = (await lockDealNFT.totalSupply()).toNumber();
      await refundProvider.connect(projectOwner).createNewRefundPool(addresses, params, tokenSignature, mainCoinsignature);
      const refundParams = [amount, amount.mul(rate).div(MAX_RATIO)];
      const timedParams = [amount, startTime, finishTime, amount];
      const collateralParams = [mainCoinAmount, finishTime, MAX_RATIO.div(10)];
      const fullData = await lockDealNFT.getFullData(poolId);
      expect(fullData).to.deep.equal([
        [refundProvider.address, name, poolId, vaultId.add(1), receiver.address, token, refundParams],
        [timedProvider.address, timedName, poolId + 1, vaultId.add(1), refundProvider.address, token, timedParams],
        [collateralProvider.address, collateralName, poolId + 2, vaultId.add(2), projectOwner.address, BUSD, collateralParams]
      ]);
    });
  });

  describe('Split Pool', async () => {
    it('should return currect pool data after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256'], [ratio]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [halfAmount, halfAmount.mul(rate).div(MAX_RATIO)];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([
        refundProvider.address,
        name,
        poolId,
        vaultId.sub(1),
        receiver.address,
        token,
        params,
      ]);
    });

    it('should return PoolSplit event after splitting', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, receiver.address]);
      const tx = await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      await tx.wait();
      const event = await lockDealNFT.queryFilter(lockDealNFT.filters.PoolSplit());
      const data = event[event.length - 1].args;
      expect(data.poolId).to.equal(poolId);
      // data + collateral(4) + 1
      expect(data.newPoolId).to.equal(poolId + 6);
      expect(data.owner).to.equal(receiver.address);
      expect(data.newOwner).to.equal(receiver.address);
      expect(data.splitLeftAmount).to.equal(amount.div(2));
      expect(data.newSplitLeftAmount).to.equal(amount.div(2));
    });

    it('should return new pool data after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256'], [ratio]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [halfAmount, halfAmount.mul(rate).div(MAX_RATIO)];
      const poolData = await lockDealNFT.getData(poolId + 6);
      expect(poolData).to.deep.equal([
        refundProvider.address,
        name,
        poolId + 6,
        vaultId.sub(1),
        receiver.address,
        token,
        params,
      ]);
    });

    it('should return old data for user after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, receiver.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount.div(2), startTime, finishTime, amount.div(2)];
      const poolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData).to.deep.equal([
        timedProvider.address,
        timedName,
        poolId + 1,
        vaultId.sub(1),
        refundProvider.address,
        token,
        params,
      ]);
    });

    it('should return new data for user after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, receiver.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount.div(2), startTime, finishTime, amount.div(2)];
      const poolData = await lockDealNFT.getData(poolId + 7);
      expect(poolData).to.deep.equal([
        timedProvider.address,
        timedName,
        poolId + 7,
        vaultId.sub(1),
        refundProvider.address,
        token,
        params,
      ]);
    });
  });

  describe('Withdraw Pool', async () => {
    it('should withdraw tokens from pool after time', async () => {
      await time.setNextBlockTimestamp(finishTime + 1);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const poolData = await lockDealNFT.getData(poolId + 1);
      const params = [0, startTime, finishTime, amount];
      expect(poolData).to.deep.equal([
        timedProvider.address,
        timedName,
        poolId + 1,
        vaultId.sub(1),
        refundProvider.address,
        token,
        params,
      ]);
    });

    it('should withdraw half tokens from pool after halfTime', async () => {
      await time.setNextBlockTimestamp(startTime + halfTime);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const params = [amount.div(2), startTime, finishTime, amount];
      const poolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData).to.deep.equal([
        timedProvider.address,
        timedName,
        poolId + 1,
        vaultId.sub(1),
        refundProvider.address,
        token,
        params,
      ]);
    });

    it('should withdraw with DealProvider', async () => {
      poolId = (await lockDealNFT.totalSupply()).toNumber();
      const params = [amount, halfAmount, finishTime];
      addresses = [receiver.address, token, BUSD, dealProvider.address];
      await refundProvider
        .connect(projectOwner)
        .createNewRefundPool(addresses, params, tokenSignature, mainCoinsignature);
      vaultId = await mockVaultManager.Id();
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const poolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData).to.deep.equal([
        dealProvider.address,
        'DealProvider',
        poolId + 1,
        vaultId.sub(1),
        refundProvider.address,
        token,
        [0],
      ]);
    });

    it('should increase token collector pool after halfTime', async () => {
      await time.setNextBlockTimestamp(startTime + halfTime);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const params = [mainCoinAmount.div(2)];
      const poolData = await lockDealNFT.getData(poolId + 3);
      expect(poolData).to.deep.equal([
        dealProvider.address,
        'DealProvider',
        poolId + 3,
        vaultId,
        collateralProvider.address,
        BUSD,
        params,
      ]);
    });

    it('should get zero tokens from pool before time', async () => {
      const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId);
      expect(withdrawAmount).to.equal(0);
    });

    it('should get full amount after time', async () => {
      await time.setNextBlockTimestamp(finishTime);
      await mine(1);
      const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId);
      expect(withdrawAmount).to.equal(amount);
    });

    it('should get half amount', async () => {
      await time.setNextBlockTimestamp(startTime + halfTime);
      await mine(1);
      const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId);
      expect(withdrawAmount).to.equal(amount.div(2));
    });
  });

  describe('Refund Pool', async () => {
    it('the user receives the main coins', async () => {
      addresses[3] = lockProvider.address;
      await refundProvider
        .connect(projectOwner)
        .createNewRefundPool(addresses, params, tokenSignature, mainCoinsignature);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, refundProvider.address, poolId);
      const newMainCoinPoolId = (await lockDealNFT.totalSupply()).toNumber() - 1;
      const poolData = await lockDealNFT.getData(newMainCoinPoolId);
      expect(poolData).to.deep.equal([
        dealProvider.address,
        'DealProvider',
        newMainCoinPoolId,
        vaultId,
        receiver.address,
        BUSD,
        [mainCoinAmount],
      ]);
    });

    it('the project owner receives the tokens', async () => {
      addresses[3] = lockProvider.address;
      await refundProvider
        .connect(projectOwner)
        .createNewRefundPool(addresses, params, tokenSignature, mainCoinsignature);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, refundProvider.address, poolId);
      const poolData = await lockDealNFT.getData(poolId + 4);
      expect(poolData).to.deep.equal([
        dealProvider.address,
        'DealProvider',
        poolId + 4,
        vaultId.sub(1),
        collateralProvider.address,
        token,
        [amount],
      ]);
    });
  });
});
