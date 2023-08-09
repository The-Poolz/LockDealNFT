import { LockDealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { MockVaultManager } from '../typechain-types';
import { deployed, token, MAX_RATIO } from './helper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Lock Deal Provider', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let lockDealNFT: LockDealNFT;
  let mockVaultManager: MockVaultManager;
  let poolId: number;
  let params: [number, number];
  let receiver: SignerWithAddress;
  let newOwner: SignerWithAddress;
  let startTime: number;
  let vaultId: BigNumber;
  const amount = 10000;
  const ratio = MAX_RATIO.div(2); // half of the amount

  before(async () => {
    [receiver, newOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + 100;
    params = [amount, startTime];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    await lockProvider.createNewPool(receiver.address, token, params);
    vaultId = await mockVaultManager.Id();
  });

  it('should return provider name', async () => {
    expect(await lockProvider.name()).to.equal('LockDealProvider');
  });

  it('should check cascade pool creation events', async () => {
    const tx = await lockProvider.createNewPool(receiver.address, token, params);
    await tx.wait();
    const event = await dealProvider.queryFilter(dealProvider.filters.NewPoolCreated());
    expect(event[event.length - 1].args.poolId).to.equal(poolId + 1);
    expect(event[event.length - 1].args.token).to.equal(token);
    expect(event[event.length - 1].args.owner).to.equal(receiver.address);
    expect(event[event.length - 1].args.params[0]).to.equal(amount);
  });

  it('should get lock provider data after creation', async () => {
    const poolData = await lockDealNFT.getData(poolId);
    const params = [amount, startTime];
    expect(poolData).to.deep.equal([lockProvider.address, poolId, vaultId, receiver.address, token, params]);
  });

  it('should revert if the start time is invalid', async () => {
    const invalidParams = [amount, startTime - 100];
    await expect(lockProvider.createNewPool(receiver.address, token, invalidParams)).to.be.revertedWith(
      'Invalid start time',
    );
  });

  it('should revert zero owner address', async () => {
    await expect(lockProvider.createNewPool(receiver.address, constants.AddressZero, params)).to.be.revertedWith(
      'Zero Address is not allowed',
    );
  });

  it('should revert zero token address', async () => {
    await expect(lockProvider.createNewPool(constants.AddressZero, token, params)).to.be.revertedWith(
      'Zero Address is not allowed',
    );
  });

  describe('Lock Split Amount', () => {
    it('should check data in old pool after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount / 2, startTime];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([lockProvider.address, poolId, vaultId, receiver.address, token, params]);
    });

    it('should check data in new pool after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount / 2, startTime];
      const poolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData).to.deep.equal([lockProvider.address, poolId + 1, vaultId, newOwner.address, token, params]);
    });
  });

  describe('Lock Deal Withdraw', () => {
    it('should withdraw tokens', async () => {
      await time.increase(3600);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const params = ['0', startTime];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([lockProvider.address, poolId, vaultId, lockDealNFT.address, token, params]);
    });

    it('getWithdrawableAmount should return zero before startTime', async () => {
      const withdrawableAmount = await lockProvider.getWithdrawableAmount(poolId);
      expect(withdrawableAmount.toString()).to.equal('0');
    });

    it('getWithdrawableAmount should return full amount after startTime', async () => {
      await time.increase(3600);
      const withdrawableAmount = await lockProvider.getWithdrawableAmount(poolId);
      expect(withdrawableAmount).to.equal(amount);
    });
  });
});
