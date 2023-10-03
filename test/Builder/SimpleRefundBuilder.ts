import { MockVaultManager } from '../../typechain-types';
import { DealProvider } from '../../typechain-types';
import { LockDealNFT } from '../../typechain-types';
import { LockDealProvider } from '../../typechain-types';
import { TimedDealProvider } from '../../typechain-types';
import { CollateralProvider } from '../../typechain-types';
import { RefundProvider } from '../../typechain-types';
import { SimpleRefundBuilder } from '../../typechain-types';
import { deployed, token, BUSD, _createUsers } from '.././helper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Simple Refund Builder tests', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let mockVaultManager: MockVaultManager;
  let timedProvider: TimedDealProvider;
  let simpleRefundBuilder: SimpleRefundBuilder;
  let lockDealNFT: LockDealNFT;
  let userData: SimpleRefundBuilder.BuilderStruct;
  let addressParams: [string, string, string];
  let projectOwner: SignerWithAddress;
  let startTime: BigNumber, finishTime: BigNumber;
  let mainCoinAmount = ethers.utils.parseEther('10');
  const amount = ethers.utils.parseEther('100').toString();
  const ONE_DAY = 86400;
  const gasLimit = 130_000_000;
  let refundProvider: RefundProvider;
  let collateralProvider: CollateralProvider;
  let vaultId: number;
  let poolId: number;

  async function _testMassPoolsData(provider: string, amount: string, userCount: string, params: string[][]) {
    userData = await _createUsers(amount, userCount);
    await simpleRefundBuilder.connect(projectOwner).buildMassPools(addressParams, userData, params, { gasLimit });
    const lastPoolId = (await lockDealNFT.totalSupply()).toNumber();
    await _logGasPrice(params);
    params[1].splice(0, 0, amount);
    if (provider == timedProvider.address) {
      params[1].push(amount);
    }
    const collateralId = poolId + 2;
    const tokenVaultId = vaultId + 1;
    vaultId += 1;
    await _checkRefundProviderData(poolId, collateralId, userData.userPools[0].user, constants.AddressZero, 0);
    await _checkSimpleProviderData(provider, poolId + 1, params[1], tokenVaultId);
    await _checkCollateralData(collateralId, params[0]);
    let k = 1;
    for(let i = poolId + 6; i < lastPoolId; i += 2) {
      await _checkRefundProviderData(i, collateralId, userData.userPools[k++].user, constants.AddressZero, 0);
      await _checkSimpleProviderData(provider, i + 1, params[1], tokenVaultId);
    }
  }

  async function _logGasPrice(params: string[][]) {
    const tx = await simpleRefundBuilder
      .connect(projectOwner)
      .buildMassPools(addressParams, userData, params, { gasLimit });
    const txReceipt = await tx.wait();
    const gasUsed = txReceipt.gasUsed;
    const GREEN_TEXT = '\x1b[32m';
    console.log(`${GREEN_TEXT}Gas Used: ${gasUsed.toString()}`);
    console.log(`${GREEN_TEXT}Price per one pool: ${gasUsed.div(userData.userPools.length)}`);
  }

  async function _checkRefundProviderData(poolId: number, collateralId: number, user: string, token: string, vaultId: number) {
    const params = [amount, collateralId];
    const poolData = await lockDealNFT.getData(poolId);
    expect(poolData).to.deep.equal([refundProvider.address, poolId, vaultId, user, token, params]);
  }

  async function _checkCollateralData(collateralId: number, params: string[]) {
    vaultId += 1;
    const rate = ethers.utils.parseUnits('0.1', 21).toString();
    params.push(rate)
    const poolData = await lockDealNFT.getData(collateralId);
    expect(poolData).to.deep.equal([collateralProvider.address, collateralId, vaultId, projectOwner.address, BUSD, params]);
  }

  async function _checkSimpleProviderData(provider: string, simplePoolId: number, params: string[], vaultId: number) {
    const poolData = await lockDealNFT.getData(simplePoolId);
    expect(poolData).to.deep.equal([provider, simplePoolId, vaultId, refundProvider.address, token, params]);
  }

  function _createProviderParams(provider: string): string[][] {
    addressParams[0] = provider;
    return provider == dealProvider.address
      ? [[mainCoinAmount.toString(), finishTime.toString()], []]
      : provider == lockProvider.address
      ? [[mainCoinAmount.toString(), finishTime.toString()], [finishTime.toString()]]
      : [
          [mainCoinAmount.toString(), finishTime.toString()],
          [startTime.toString(), finishTime.toString()],
        ];
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
      collateralProvider.address
    );
    await lockDealNFT.setApprovedContract(refundProvider.address, true);
    await lockDealNFT.setApprovedContract(lockProvider.address, true);
    await lockDealNFT.setApprovedContract(dealProvider.address, true);
    await lockDealNFT.setApprovedContract(timedProvider.address, true);
    await lockDealNFT.setApprovedContract(collateralProvider.address, true);
    await lockDealNFT.setApprovedContract(lockDealNFT.address, true);
    await lockDealNFT.setApprovedContract(simpleRefundBuilder.address, true);
  });

  beforeEach(async () => {
    vaultId = (await mockVaultManager.Id()).toNumber();
    userData = await _createUsers(amount, '4');
    addressParams = [timedProvider.address, token, BUSD];
    startTime = ethers.BigNumber.from((await time.latest()) + ONE_DAY); // plus 1 day
    finishTime = startTime.add(7 * ONE_DAY); // plus 7 days from `startTime`
    poolId = (await lockDealNFT.totalSupply()).toNumber();
  });

  it('should create 10 simple refund pools with dealProvider', async () => {
    const userCount = '10';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(dealProvider.address);
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 50 simple refund pools with dealProvider', async () => {
    const userCount = '50';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(dealProvider.address);
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 100 simple refund pools with dealProvider', async () => {
    const userCount = '100';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(dealProvider.address);
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 10 simple refund pools with lockProvider', async () => {
    const userCount = '10';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(lockProvider.address);
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 50 simple refund pools with lockProvider', async () => {
    const userCount = '50';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(lockProvider.address);
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 100 simple refund pools with lockProvider', async () => {
    const userCount = '100';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(lockProvider.address);
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 10 simple refund pools with timedProvider', async () => {
    const userCount = '10';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(timedProvider.address);
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });

  it('should create 50 simple refund pools with timedProvider', async () => {
    const userCount = '50';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(timedProvider.address);
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });

  it('should create 100 simple refund pools with timedProvider', async () => {
    const userCount = '100';
    mainCoinAmount = ethers.utils.parseEther('10').mul(userCount);
    const params = _createProviderParams(timedProvider.address);
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });
});
