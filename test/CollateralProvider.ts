import { MockVaultManager } from '../typechain-types';
import { CollateralProvider } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { MockProvider } from '../typechain-types';
import { deployed, token, MAX_RATIO } from './helper';
import { time, mine } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Collateral Provider', function () {
  let dealProvider: DealProvider;
  let collateralProvider: CollateralProvider;
  let lockDealNFT: LockDealNFT;
  let mockProvider: MockProvider;
  let mockVaultManager: MockVaultManager;
  let poolId: number;
  let params: [number, number];
  let receiver: SignerWithAddress;
  let projectOwner: SignerWithAddress;
  let finishTime: number;
  let vaultId: BigNumber;
  const halfRatio = MAX_RATIO.div(2);
  const amount = 100000;

  before(async () => {
    [receiver, projectOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    collateralProvider = await deployed('CollateralProvider', lockDealNFT.address, dealProvider.address);
    mockProvider = await deployed('MockProvider', lockDealNFT.address, collateralProvider.address);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(collateralProvider.address, true);
    await lockDealNFT.setApprovedProvider(mockProvider.address, true);
  });

  beforeEach(async () => {
    const ONE_DAY = 86400;
    finishTime = (await time.latest()) + 14 * ONE_DAY; // plus 14 days
    params = [amount, finishTime];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    await mockProvider.createNewPool(projectOwner.address, token, params);
    vaultId = await mockVaultManager.Id();
  });

  it('should return provider name', async () => {
    expect(await collateralProvider.name()).to.equal('CollateralProvider');
  });

  it('should revert invalid zero address before creation', async () => {
    await expect(deployed('CollateralProvider', lockDealNFT.address, constants.AddressZero)).to.be.revertedWith(
      'invalid address',
    );
  });

  it('should register new collateral pool', async () => {
    const poolData = await lockDealNFT.getData(poolId);
    const params = [amount, finishTime];
    expect(poolData).to.deep.equal([collateralProvider.address, poolId, vaultId, projectOwner.address, token, params]);
  });

  it('should create main coin deal provider pool', async () => {
    const poolData = await lockDealNFT.getData(poolId + 1);
    const params = [0];
    expect(poolData).to.deep.equal([
      dealProvider.address,
      poolId + 1,
      0,
      collateralProvider.address,
      constants.AddressZero,
      params,
    ]);
  });

  it('should create token provider pool', async () => {
    const poolData = await lockDealNFT.getData(poolId + 2);
    const params = [0];
    expect(poolData).to.deep.equal([
      dealProvider.address,
      poolId + 2,
      0,
      collateralProvider.address,
      constants.AddressZero,
      params,
    ]);
  });

  it('should revert invalid finish time', async () => {
    await expect(
      mockProvider.createNewPool(receiver.address, token, [amount, (await time.latest()) - 1]),
    ).to.be.revertedWith('start time must be in the future');
  });

  it('should deposit tokens', async () => {
    await mockProvider.handleRefund(poolId, amount, amount / 2);
    const tokenCollectorId = poolId + 2;
    const mainCoinHolderId = poolId + 3;
    let poolData = await lockDealNFT.getData(tokenCollectorId);
    expect(poolData.params[0]).to.equal(amount);
    poolData = await lockDealNFT.getData(mainCoinHolderId);
    expect(poolData.params[0]).to.equal(amount / 2);
  });

  it('should deposit main coin', async () => {
    await mockProvider.handleWithdraw(poolId, amount / 2);
    const mainCoinCollectorId = poolId + 1;
    const mainCoinHolderId = poolId + 3;
    let poolData = await lockDealNFT.getData(mainCoinHolderId);
    expect(poolData.params[0]).to.equal(amount / 2);
    poolData = await lockDealNFT.getData(mainCoinCollectorId);
    expect(poolData.params[0]).to.equal(amount / 2);
  });

  it('only NFT can manage withdraw', async () => {
    await expect(collateralProvider['withdraw(uint256)'](poolId)).to.be.revertedWith(
      'only NFT contract can call this function',
    );
  });

  it('should withdraw before time main coins', async () => {
    await mockProvider.handleWithdraw(poolId, amount / 2);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256)'](projectOwner.address, lockDealNFT.address, poolId);
    expect((await lockDealNFT.getData(poolId + 1)).params[0]).to.deep.equal(amount / 2);
    expect((await lockDealNFT.getData(poolId + 2)).params[0]).to.deep.equal(0);
    expect((await lockDealNFT.getData(poolId + 3)).params[0]).to.deep.equal(0);
  });

  it('should withdraw tokens before time', async () => {
    await mockProvider.handleRefund(poolId, amount / 2, amount / 2);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256)'](projectOwner.address, lockDealNFT.address, poolId);
    expect((await lockDealNFT.getData(poolId + 1)).params[0]).to.deep.equal(0);
    expect((await lockDealNFT.getData(poolId + 2)).params[0]).to.deep.equal(0);
    expect((await lockDealNFT.getData(poolId + 3)).params[0]).to.deep.equal(0);
  });

  it('should withdraw main coins and tokens before time', async () => {
    await mockProvider.handleWithdraw(poolId, amount / 2);
    await mockProvider.handleRefund(poolId, amount / 2, amount / 2);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256)'](projectOwner.address, lockDealNFT.address, poolId);
    expect((await lockDealNFT.getData(poolId + 1)).params[0]).to.deep.equal(amount / 2);
    expect((await lockDealNFT.getData(poolId + 2)).params[0]).to.deep.equal(0);
    expect((await lockDealNFT.getData(poolId + 3)).params[0]).to.deep.equal(0);
  });

  it('should transfer all pools to NFT after finish time', async () => {
    await time.setNextBlockTimestamp(finishTime + 1);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256)'](projectOwner.address, lockDealNFT.address, poolId);
    expect((await lockDealNFT.getData(poolId + 1)).params[0]).to.deep.equal(0);
    expect((await lockDealNFT.getData(poolId + 2)).params[0]).to.deep.equal(0);
    expect((await lockDealNFT.getData(poolId + 3)).params[0]).to.deep.equal(0);
  });

  it('should get zero amount before time', async () => {
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
    await mockProvider.handleWithdraw(poolId, amount / 2);
    const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId);
    expect(withdrawAmount).to.equal(amount / 2);
  });

  it('should create 4 new pools after split', async () => {
    await time.setNextBlockTimestamp(finishTime + 1);
    const totalSupply = await lockDealNFT.totalSupply();
    const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [halfRatio, projectOwner.address]);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        projectOwner.address,
        lockDealNFT.address,
        poolId,
        packedData,
      );
    // check that all pools was created
    expect(await lockDealNFT.totalSupply()).to.equal(totalSupply.add(4));
  });

  it('should return a PoolSplit event after splitting', async () => {
    await time.setNextBlockTimestamp(finishTime + 1);
    const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [halfRatio, projectOwner.address]);
    const tx = await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        projectOwner.address,
        lockDealNFT.address,
        poolId,
        packedData,
      );
    await tx.wait();
    const events = await lockDealNFT.queryFilter(lockDealNFT.filters.PoolSplit());
    expect(events[events.length - 1].args.poolId).to.equal(poolId);
    // poolId + 1 main coin collector | poolId + 2 token collector | poolId + 3 main coin holder | poolId + 4 new pool
    expect(events[events.length - 1].args.newPoolId).to.equal(poolId + 4);
    expect(events[events.length - 1].args.owner).to.equal(projectOwner.address);
    expect(events[events.length - 1].args.newOwner).to.equal(projectOwner.address);
    expect(events[events.length - 1].args.splitLeftAmount).to.equal(amount / 2);
    expect(events[events.length - 1].args.newSplitLeftAmount).to.equal(amount / 2);
  });

  it('should split Main Coin Collector pool', async () => {
    await mockProvider.handleWithdraw(poolId, amount / 2);
    const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [halfRatio, projectOwner.address]);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        projectOwner.address,
        lockDealNFT.address,
        poolId,
        packedData,
      );
    const mainCoinCollectorId = poolId + 1;
    const newMainCoinCoolectorId = mainCoinCollectorId + 4;
    const poolData = await lockDealNFT.getData(mainCoinCollectorId);
    const newPoolData = await lockDealNFT.getData(newMainCoinCoolectorId);
    expect(poolData.params[0]).to.equal(amount / 4);
    expect(newPoolData.params[0]).to.equal(amount / 4);
  });

  it('should split Token Collector pool', async () => {
    await mockProvider.handleRefund(poolId, amount / 2, amount / 2);
    const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [halfRatio, projectOwner.address]);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        projectOwner.address,
        lockDealNFT.address,
        poolId,
        packedData,
      );
    const tokenCollectorId = poolId + 2;
    const newTokenCoolectorId = tokenCollectorId + 4;
    const poolData = await lockDealNFT.getData(tokenCollectorId);
    const newPoolData = await lockDealNFT.getData(newTokenCoolectorId);
    expect(poolData.params[0]).to.equal(amount / 4);
    expect(newPoolData.params[0]).to.equal(amount / 4);
  });

  it('should split main coin holder pool', async () => {
    await time.setNextBlockTimestamp(finishTime + 1);
    const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [halfRatio, projectOwner.address]);
    await lockDealNFT
      .connect(projectOwner)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        projectOwner.address,
        lockDealNFT.address,
        poolId,
        packedData,
      );
    const coinHolderId = poolId + 3;
    const newCoinHolderId = poolId + 4;
    const poolData = await lockDealNFT.getData(coinHolderId);
    const newPoolData = await lockDealNFT.getData(newCoinHolderId);
    expect(poolData.params[0]).to.equal(amount / 2);
    expect(newPoolData.params[0]).to.equal(amount / 2);
  });
});
