import { LockDealProvider } from '../typechain-types';
import { TimedDealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { MockVaultManager } from '../typechain-types';
import { MultiWithdrawProvider } from '../typechain-types';
import { MockProvider } from '../typechain-types';
import { BundleProvider } from '../typechain-types';
import { deployed, token, BUSD } from './helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

describe('Lock Deal Bundle Provider', function () {
  let bundleProvider: BundleProvider;
  let mockProvider: MockProvider;
  let timedDealProvider: TimedDealProvider;
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let lockDealNFT: LockDealNFT;
  let mockVaultManager: MockVaultManager;
  let multiWithdrawProvider: MultiWithdrawProvider;
  let receiver: SignerWithAddress;
  let poolId: number;
  const amount = BigNumber.from(100000);
  const MAX_TRANSACTIONS = '100';

  before(async () => {
    [receiver] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    timedDealProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
    bundleProvider = await deployed('BundleProvider', lockDealNFT.address);
    mockProvider = await deployed('MockProvider', lockDealNFT.address, bundleProvider.address);
    multiWithdrawProvider = await deployed('MultiWithdrawProvider', lockDealNFT.address, MAX_TRANSACTIONS);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(multiWithdrawProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedDealProvider.address, true);
    await lockDealNFT.setApprovedProvider(bundleProvider.address, true);
    await lockDealNFT.setApprovedProvider(mockProvider.address, true);

    // create multiWithdraw pool
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    await multiWithdrawProvider.createNewPool(receiver.address);
  });

  it('should create 10 deal pools', async () => {
    for (let i = 0; i < 10; i++) {
      if (i % 2 == 0) {
        await dealProvider.createNewPool(receiver.address, token, [amount]);
      } else {
        await dealProvider.createNewPool(receiver.address, BUSD, [amount.div(2)]);
      }
    }
    // 10 deals + 1 multi withdraw pool
    expect(await lockDealNFT.balanceOf(receiver.address)).to.equal(11);
  });

  it('check that all funds are withdrawn', async () => {
    await lockDealNFT
      .connect(receiver)
      ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
    const params = [0];
    for (let i = 1; i < 11; i++) {
      const poolData = await lockDealNFT.getData(i);
      expect(poolData.params).to.deep.equal(params);
    }
  });
});
