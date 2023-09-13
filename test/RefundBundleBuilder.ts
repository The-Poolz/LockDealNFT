import { MockVaultManager } from '../typechain-types';
import { CollateralProvider } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { LockDealProvider } from '../typechain-types';
import { RefundProvider } from '../typechain-types';
import { TimedDealProvider } from '../typechain-types';
import { RefundBundleBuilder } from '../typechain-types/';
import { BundleProvider } from '../typechain-types/';
import { deployed, token, BUSD } from './helper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

describe('Builder', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let mockVaultManager: MockVaultManager;
  let refundProvider: RefundProvider;
  let timedProvider: TimedDealProvider;
  let collateralProvider: CollateralProvider;
  let bundleProvider: BundleProvider;
  let bundleBuilder: RefundBundleBuilder;
  let vaultId: number;
  let lockDealNFT: LockDealNFT;
  let poolId: number;
  let userSplits: [
    { user: string; amount: string },
    { user: string; amount: string },
    { user: string; amount: string },
    { user: string; amount: string },
  ];
  let addressParams: [string, string, string, string];
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;
  let projectOwner: SignerWithAddress;
  let params: [(number | BigNumber)[], (string | number)[], (string | number)[]];
  let startTime: number, finishTime: number;
  const mainCoinAmount = ethers.utils.parseEther('40'); // 10% of 400
  const amount = ethers.utils.parseEther('100').toString();
  const ONE_DAY = 86400;

  before(async () => {
    [user1, user2, user3, projectOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    const baseURI = 'https://nft.poolz.finance/test/metadata/';
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, baseURI);
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    timedProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
    collateralProvider = await deployed('CollateralProvider', lockDealNFT.address, dealProvider.address);
    refundProvider = await deployed('RefundProvider', lockDealNFT.address, collateralProvider.address);
    bundleProvider = await deployed('BundleProvider', lockDealNFT.address);
    bundleBuilder = await deployed(
      'RefundBundleBuilder',
      lockDealNFT.address,
      refundProvider.address,
      bundleProvider.address,
      collateralProvider.address,
    );
    await lockDealNFT.setApprovedProvider(refundProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedProvider.address, true);
    await lockDealNFT.setApprovedProvider(collateralProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockDealNFT.address, true);
    await lockDealNFT.setApprovedProvider(bundleProvider.address, true);
    await lockDealNFT.setApprovedProvider(bundleBuilder.address, true);
  });

  beforeEach(async () => {
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    userSplits = [
      // 400 total amount
      { user: user1.address, amount: amount },
      { user: user2.address, amount: amount },
      { user: user3.address, amount: amount },
      { user: user3.address, amount: amount },
    ];
    addressParams = [token, BUSD, timedProvider.address, lockProvider.address];
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
    const paramsAmount = ethers.utils.parseEther('200').toString();
    params = [
      [mainCoinAmount, finishTime],
      [paramsAmount, startTime, finishTime],
      [paramsAmount, startTime],
    ];
    vaultId = (await mockVaultManager.Id()).toNumber() + 1;
    await bundleBuilder.connect(projectOwner).buildRefundBundle(userSplits, addressParams, params);
  });

  // 0 - refund
  // 1 - bundle (1, 2, 3)
  // 2 - collateral (4, 5, 6, 7)
  it('should check collateral data after builder creation', async () => {
    poolId += 4; // collateral pool id
    const poolData = await lockDealNFT.getData(poolId);
    vaultId = (await mockVaultManager.Id()).toNumber();
    const params = [mainCoinAmount, finishTime];
    expect(poolData).to.deep.equal([collateralProvider.address, poolId, vaultId, projectOwner.address, BUSD, params]);
  });

  it('check starter refund provider data after builder creation', async () => {
    const collateralPoolId = await refundProvider.poolIdToCollateralId(poolId);
    const rateToWei = await refundProvider.poolIdToRateToWei(poolId);
    expect(collateralPoolId).to.equal(poolId + userSplits.length);
    expect(rateToWei).to.equal(ethers.utils.parseEther('0.1').toString());
  });

  // 0 - refund
  // 1 - bundle (1, 2, 3)
  // 2 - collateral (4, 5, 6, 7)
  it('should check users refund user pools after builder creation', async () => {
    const collateralPoolId = poolId + 4;
    poolId += 8; // users pool ids start from poolId + 8
    for (let i = poolId; i < poolId + userSplits.length * 3; i += 4) {
      const userData = await lockDealNFT.getData(i);
      expect(userData.provider).to.equal(refundProvider.address);
      expect(userData.poolId).to.equal(i);
      expect(userData.owner).to.equal(userSplits[(i - poolId) / 4].user);
      expect(userData.token).to.equal(token);
      expect(userData.params).to.deep.equal([amount, collateralPoolId, ethers.utils.parseEther('0.1').toString()]);
    }
  });
});
