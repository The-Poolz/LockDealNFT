import { MockVaultManager } from '../../typechain-types';
import { DealProvider } from '../../typechain-types';
import { LockDealNFT } from '../../typechain-types';
import { LockDealProvider } from '../../typechain-types';
import { TimedDealProvider } from '../../typechain-types';
import { CollateralProvider } from '../../typechain-types';
import { RefundProvider } from '../../typechain-types';
import { SimpleRefundBuilder } from '../../typechain-types';
import { deployed, token, BUSD, _createUsers, _logGasPrice } from '.././helper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Bytes, constants } from 'ethers';
import { ethers } from 'hardhat';
import { BuilderState } from '../../typechain-types/contracts/Builders/SimpleBuilder/SimpleBuilder';

describe('Simple Refund Builder tests', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let mockVaultManager: MockVaultManager;
  let timedProvider: TimedDealProvider;
  let simpleRefundBuilder: SimpleRefundBuilder;
  let lockDealNFT: LockDealNFT;
  let userData: BuilderState.BuilderStruct;
  let addressParams: [string, string, string];
  let projectOwner: SignerWithAddress;
  let startTime: BigNumber, finishTime: BigNumber;
  let mainCoinAmount = ethers.utils.parseEther('10');
  const amount = ethers.utils.parseEther('100').toString();
  const ONE_DAY = 86400;
  const gasLimit = 130_000_000;
  const rate = ethers.utils.parseUnits('0.1', 21);
  const tokenSignature: Bytes = ethers.utils.toUtf8Bytes('signature');
  const mainCoinsignature: Bytes = ethers.utils.toUtf8Bytes('signature');
  let refundProvider: RefundProvider;
  let collateralProvider: CollateralProvider;
  let vaultId: number;
  let poolId: number;

  async function _testMassPoolsData(provider: string, amount: string, userCount: string, params: string[][]) {
    userData = _createUsers(amount, userCount);
    const tx = await simpleRefundBuilder.connect(projectOwner).buildMassPools(addressParams, userData, params, tokenSignature, mainCoinsignature, { gasLimit });
    const txReceipt = await tx.wait();
    const lastPoolId = (await lockDealNFT.totalSupply()).toNumber();
    _logGasPrice(txReceipt, userData.userPools.length);
    params[1].splice(0, 0, amount);
    if (provider == timedProvider.address) {
      params[1].push(amount);
    }
    const name = provider == dealProvider.address ? 'DealProvider' : provider == lockProvider.address ? 'LockDealProvider' : 'TimedDealProvider';
    const collateralId = poolId + 2;
    const tokenVaultId = vaultId + 1;
    vaultId += 1;
    await Promise.all([
      _checkRefundProviderData(poolId, collateralId, poolId + 1, await userData.userPools[0].user , constants.AddressZero, 0),
      _checkSimpleProviderData(provider, name, poolId + 1, params[1], tokenVaultId),
      _checkCollateralData(collateralId)
    ])

    let k = 1;
    const poolIdsAndUsers : {poolId: number, user: number}[] = []
    for (let i = poolId + 6; i < lastPoolId; i += 6) {
      poolIdsAndUsers.push({poolId: i, user: k})
      k += 3;
    }

    const allChecks = poolIdsAndUsers.map( async (i) => {
      return Promise.all([
        _checkRefundProviderData(i.poolId, collateralId, i.poolId + 1, await userData.userPools[i.user].user , constants.AddressZero, 0),
        _checkSimpleProviderData(provider, name, i.poolId + 1, params[1], tokenVaultId),
      ])
    })
    await Promise.all(allChecks)

  }

  async function _checkRefundProviderData(poolId: number, collateralId: number,  simplePoolId: number, user: string, token: string, vaultId: number) {
    const simpleData = await lockDealNFT.getData(simplePoolId);
    const params = [simpleData.params[0], rate, ethers.BigNumber.from(collateralId), ...simpleData.params.slice(1)];
    const poolData = await lockDealNFT.getData(poolId);
    expect(poolData).to.deep.equal([refundProvider.address, 'RefundProvider', poolId, vaultId, user, token, params]);
  }

  async function _checkCollateralData(collateralId: number) {
    vaultId += 1;
    const params = [mainCoinAmount.toString(), finishTime.toString(), rate];
    const poolData = await lockDealNFT.getData(collateralId);
    expect(poolData).to.deep.equal([collateralProvider.address, 'CollateralProvider', collateralId, vaultId, projectOwner.address, BUSD, params]);
  }

  async function _checkSimpleProviderData(provider: string, name: string, simplePoolId: number, params: string[], vaultId: number) {
    const poolData = await lockDealNFT.getData(simplePoolId);
    expect(poolData).to.deep.equal([provider, name, simplePoolId, vaultId, refundProvider.address, token, params]);
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
      collateralProvider.address,
    );
    await Promise.all([
      lockDealNFT.setApprovedContract(refundProvider.address, true),
      lockDealNFT.setApprovedContract(lockProvider.address, true),
      lockDealNFT.setApprovedContract(dealProvider.address, true),
      lockDealNFT.setApprovedContract(timedProvider.address, true),
      lockDealNFT.setApprovedContract(collateralProvider.address, true),
      lockDealNFT.setApprovedContract(lockDealNFT.address, true),
      lockDealNFT.setApprovedContract(simpleRefundBuilder.address, true),
    ])
  });

  beforeEach(async () => {
    vaultId = (await mockVaultManager.Id()).toNumber();
    userData = _createUsers(amount, '4');
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
