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
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

describe('test-driven development', function () {
  let bundleProvider: BundleProvider;
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let bundleMockProvider: MockProvider;
  let refundMockProvider: MockProvider;
  let refundProvider: RefundProvider;
  let timedProvider: TimedDealProvider;
  let mockVaultManager: MockVaultManager;
  let collateralProvider: CollateralProvider;
  const rate = ethers.utils.parseEther('0.1');
  const mainCoinAmount = ethers.utils.parseEther('10');
  let lockDealNFT: LockDealNFT;
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
    refundMockProvider = await deployed('MockProvider', lockDealNFT.address, refundProvider.address);
    await lockDealNFT.setApprovedProvider(refundProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedProvider.address, true);
    await lockDealNFT.setApprovedProvider(collateralProvider.address, true);
    await lockDealNFT.setApprovedProvider(bundleProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockDealNFT.address, true);
    await lockDealNFT.setApprovedProvider(bundleMockProvider.address, true);
    await lockDealNFT.setApprovedProvider(refundMockProvider.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
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

    it('should revert creation new bundle with refund provider', async () => {
      const addresses = [
        receiver.address,
        token,
        dealProvider.address,
        lockProvider.address,
        timedProvider.address,
        refundProvider.address,
      ];
      const refundProviderParams = [amount, amount.div(2), ratio, finishTime];
      params = [dealProviderParams, lockProviderParams, timedDealProviderParams, refundProviderParams];
      await expect(bundleProvider.createNewPool(addresses, params)).to.be.reverted;
    });

    it('should revert register refund provider in bundle', async () => {
      bundleProviders = [dealProvider.address, lockProvider.address, timedProvider.address, refundProvider.address];
      const refundProviderParams = [amount, amount.div(2), ratio, finishTime];
      const params = [dealProviderParams, lockProviderParams, timedDealProviderParams, refundProviderParams];
      await expect(bundleMockProvider.registerNewBundlePool(receiver.address, bundleProviders, params)).to.be.reverted;
    });

    it('should revert creation new bundle with collateral provider', async () => {
      const addresses = [
        receiver.address,
        token,
        dealProvider.address,
        lockProvider.address,
        timedProvider.address,
        collateralProvider.address,
      ];
      params = [dealProviderParams, lockProviderParams, timedDealProviderParams, lockProviderParams];
      await expect(bundleProvider.createNewPool(addresses, params)).to.be.reverted;
    });

    it('should revert register collateral provider in bundle', async () => {
      bundleProviders = [dealProvider.address, lockProvider.address, timedProvider.address, collateralProvider.address];
      const params = [dealProviderParams, lockProviderParams, timedDealProviderParams, lockProviderParams];
      await expect(bundleMockProvider.registerNewBundlePool(receiver.address, bundleProviders, params)).to.be.reverted;
    });
  });

  describe('Refund Provider', async () => {
    let params: [BigNumber, number, number, BigNumber, BigNumber, number];

    beforeEach(async () => {
      params = [amount, startTime, finishTime, mainCoinAmount, rate, finishTime];
    });

    it('should revert creation of a new refund with sub refund provider', async () => {
      await expect(
        refundProvider
          .connect(projectOwner)
          .createNewRefundPool([token, receiver.address, BUSD, refundProvider.address], params),
      ).to.be.reverted;
    });

    it('should revert register sub refund provider in refund', async () => {
      await expect(refundMockProvider.registerNewRefundPool(receiver.address, refundProvider.address)).to.be.reverted;
    });

    it('should revert register bundle id instead collateral in refund', async () => {
      await expect(refundMockProvider.registerNewRefundPool(receiver.address, bundleProvider.address)).to.be.reverted;
    });

    it('should be revert, wrong pool id in refund register', async () => {
      await collateralProvider.createNewPool([receiver.address, token], [amount, startTime]);
      const poolId = (await lockDealNFT.totalSupply()).toNumber() - 1;
      const params = [poolId, ratio];
      const nonValidPoolId = 999999;
      await expect(refundMockProvider.registerPool(nonValidPoolId, params)).to.be.revertedWith(
        'Invalid provider poolId',
      );
    });
  });
});
