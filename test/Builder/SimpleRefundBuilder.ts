import { MockVaultManager } from '../../typechain-types';
import { DealProvider } from '../../typechain-types';
import { LockDealNFT } from '../../typechain-types';
import { LockDealProvider } from '../../typechain-types';
import { TimedDealProvider } from '../../typechain-types';
import { CollateralProvider } from '../../typechain-types';
import { RefundProvider } from '../../typechain-types';
import { SimpleRefundBuilder } from '../../typechain-types';
import { deployed, token, BUSD } from '.././helper';
import { _createUsers } from './BuilderHelper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

describe('Simple Refund Builder tests', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let mockVaultManager: MockVaultManager;
  let timedProvider: TimedDealProvider;
  let simpleRefundBuilder: SimpleRefundBuilder;
  let lockDealNFT: LockDealNFT;
  let userData: SimpleRefundBuilder.BuilderStruct;
  let addressParams: [string, string];
  let projectOwner: SignerWithAddress;
  let startTime: BigNumber, finishTime: BigNumber;
  const amount = ethers.utils.parseEther('100').toString();
  const ONE_DAY = 86400;
  let refundProvider: RefundProvider;
  let collateralProvider: CollateralProvider;
  let vaultId: number;
  let poolId: number;

  async function _testMassPoolsData(provider: string, amount: string, userCount: string, params: BigNumber[]) {
    userData = await _createUsers(amount, userCount);
    const lastPoolId = (await lockDealNFT.totalSupply()).toNumber();
    let k = 0;
    params.splice(0, 0, ethers.BigNumber.from(amount));
    if (provider == timedProvider.address) {
      params.push(ethers.BigNumber.from(amount));
    }
  }

  function _createProviderParams(provider: string) {
    addressParams[0] = provider;
    return provider == dealProvider.address
      ? []
      : provider == lockProvider.address
      ? [finishTime]
      : [startTime, finishTime];
  }

  before(async () => {
    [projectOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    const baseURI = 'https://nft.poolz.finance/test/metadata/';
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, baseURI);
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    timedProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
    collateralProvider = await deployed('CollateralProvider', lockDealNFT.address, dealProvider.address);
    refundProvider = await deployed('RefundProvider', lockDealNFT.address, collateralProvider.address);
    simpleRefundBuilder = await deployed(
      'SimpleRefundBuilder',
      lockDealNFT.address,
      refundProvider.address,
      collateralProvider.address,
    );
    await lockDealNFT.setApprovedProvider(refundProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedProvider.address, true);
    await lockDealNFT.setApprovedProvider(collateralProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockDealNFT.address, true);
    await lockDealNFT.setApprovedProvider(simpleRefundBuilder.address, true);
  });

  beforeEach(async () => {
    userData = await _createUsers(amount, '4');
    addressParams = [timedProvider.address, token];
    startTime = ethers.BigNumber.from((await time.latest()) + ONE_DAY); // plus 1 day
    finishTime = startTime.add(7 * ONE_DAY); // plus 7 days from `startTime`
  });

  it('should create 10 simple refund pools with dealProvider', async () => {
    const userCount = '10';
    const params = _createProviderParams(dealProvider.address);
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 50 simple refund pools with dealProvider', async () => {
    const userCount = '50';
    const params = _createProviderParams(dealProvider.address);
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 100 simple refund pools with dealProvider', async () => {
    const userCount = '100';
    const params = _createProviderParams(dealProvider.address);
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 10 simple refund pools with lockProvider', async () => {
    const userCount = '10';
    const params = _createProviderParams(lockProvider.address);
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 50 simple refund pools with lockProvider', async () => {
    const userCount = '50';
    const params = _createProviderParams(lockProvider.address);
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 100 simple refund pools with lockProvider', async () => {
    const userCount = '100';
    const params = _createProviderParams(lockProvider.address);
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 10 simple refund pools with timedProvider', async () => {
    const userCount = '10';
    const params = _createProviderParams(timedProvider.address);
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });

  it('should create 50 simple refund pools with timedProvider', async () => {
    const userCount = '50';
    const params = _createProviderParams(timedProvider.address);
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });

  it('should create 100 simple refund pools with timedProvider', async () => {
    const userCount = '100';
    const params = _createProviderParams(timedProvider.address);
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });
});
