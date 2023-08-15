import { MockVaultManager } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { LockDealProvider } from '../typechain-types';
import { BundleProvider } from '../typechain-types';
import { RefundProvider } from '../typechain-types';
import { TimedDealProvider } from '../typechain-types';
import { CollateralProvider } from '../typechain-types';
import { MockProvider } from '../typechain-types';
import { deployed, token, BUSD, MAX_RATIO } from './helper';
import { time, mine } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('test-driven development', function () {
  let bundleProvider: BundleProvider;
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let bundleMockProvider: MockProvider;

  let refundProvider: RefundProvider;
  let timedProvider: TimedDealProvider;
  let mockVaultManager: MockVaultManager;
  let collateralProvider: CollateralProvider;
  let halfTime: number;
  //   const rate = ethers.utils.parseEther('0.1');
  //   const mainCoinAmount = ethers.utils.parseEther('10');
  let lockDealNFT: LockDealNFT;
  let poolId: number;
  let vaultId: BigNumber;
  let receiver: SignerWithAddress;
  let projectOwner: SignerWithAddress;
  let startTime: number, finishTime: number;
  const amount = ethers.utils.parseEther('100');
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
    bundleProvider = await deployed('BundleProvider', lockDealNFT.address);
    bundleMockProvider = await deployed('MockProvider', lockDealNFT.address, bundleProvider.address);
    await lockDealNFT.setApprovedProvider(refundProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedProvider.address, true);
    await lockDealNFT.setApprovedProvider(collateralProvider.address, true);
    await lockDealNFT.setApprovedProvider(bundleProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockDealNFT.address, true);
    await lockDealNFT.setApprovedProvider(bundleMockProvider.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    halfTime = (finishTime - startTime) / 2;
  });

  describe('Bundle Provider', async () => {
    let bundleProviders: string[];
    let params: [BigNumber[], (number | BigNumber)[], (number | BigNumber)[], (number | BigNumber)[]];
    let dealProviderParams: [BigNumber];
    let lockProviderParams: [BigNumber, number];
    let timedDealProviderParams: [BigNumber, number, number, BigNumber];

    beforeEach(async () => {
      dealProviderParams = [amount];
      lockProviderParams = [amount, startTime];
      timedDealProviderParams = [amount, startTime, finishTime, amount];
    });

    it('try to create new bundle with refund provider', async () => {
      bundleProviders = [dealProvider.address, lockProvider.address, timedProvider.address, refundProvider.address];
      const refundProviderParams = [amount, amount.div(2), ratio, finishTime];
      params = [dealProviderParams, lockProviderParams, timedDealProviderParams, refundProviderParams];
      await expect(bundleProvider.createNewPool(receiver.address, token, bundleProviders, params)).to.be.reverted;
    });

    it('try to register refund provider in bundle', async () => {
      bundleProviders = [dealProvider.address, lockProvider.address, timedProvider.address, refundProvider.address];
      const refundProviderParams = [amount, amount.div(2), ratio, finishTime];
      const params = [dealProviderParams, lockProviderParams, timedDealProviderParams, refundProviderParams];
      await expect(bundleMockProvider.registerNewBundlePool(receiver.address, bundleProviders, params)).to.be.reverted;
    });

    it('try to create new bundle with collateral provider', async () => {
      bundleProviders = [dealProvider.address, lockProvider.address, timedProvider.address, collateralProvider.address];
      params = [dealProviderParams, lockProviderParams, timedDealProviderParams, lockProviderParams];
      await expect(bundleProvider.createNewPool(receiver.address, token, bundleProviders, params)).to.be.reverted;
    });

    it('try to register collateral provider in bundle', async () => {
      bundleProviders = [dealProvider.address, lockProvider.address, timedProvider.address, collateralProvider.address];
      const params = [dealProviderParams, lockProviderParams, timedDealProviderParams, lockProviderParams];
      await expect(bundleMockProvider.registerNewBundlePool(receiver.address, bundleProviders, params)).to.be.reverted;
    });
  });

  describe('Refund Provider', async () => {
    it('try to create new refund with refund provider', async () => {});

    it('try to register refund provider in refund', async () => {});

    it('try to create new bundle with collateral provider', async () => {});

    it('try to register collateral provider in refund', async () => {});
  });
});
