import { MockVaultManager } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { LockDealNFT } from '../typechain-types';
import { LockDealProvider } from '../typechain-types';
import { TimedDealProvider } from '../typechain-types';
import { SimpleBuilder } from '../typechain-types';
import { deployed, token } from './helper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

describe('Simple Builder tests', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let mockVaultManager: MockVaultManager;
  let timedProvider: TimedDealProvider;
  let simpleBuilder: SimpleBuilder;
  let lockDealNFT: LockDealNFT;
  let userPools: { user: string; amount: string }[];
  let addressParams: [string, string];
  let projectOwner: SignerWithAddress;
  let startTime: BigNumber, finishTime: BigNumber;
  const amount = ethers.utils.parseEther('100').toString();
  const ONE_DAY = 86400;

  // helper functions
  async function _createUsers(amount: string, userCount: string) {
    const pools = [];
    const length = parseInt(userCount);
    // Create signers
    for (let i = 0; i < length; i++) {
      const privateKey = ethers.Wallet.createRandom().privateKey;
      const signer = new ethers.Wallet(privateKey);
      const user = signer.address;
      pools.push({ user: user, amount: amount });
    }
    return pools;
  }

  async function _testMassPoolsData(provider: string, amount: string, userCount: string, params: BigNumber[]) {
    userPools = await _createUsers(amount, userCount);
    const lastPoolId = (await lockDealNFT.totalSupply()).toNumber();
    await simpleBuilder.connect(projectOwner).buildMassPools(addressParams, userPools, params);
    await _logGasPrice(params);
    let k = 0;
    params.splice(0, 0, ethers.BigNumber.from(amount));
    if (provider == timedProvider.address) {
      params.push(ethers.BigNumber.from(amount));
    }
    for (let i = lastPoolId + 1; i < userPools.length + lastPoolId; i++) {
      const userData = await lockDealNFT.getData(i);
      expect(userData.provider).to.equal(provider);
      expect(userData.poolId).to.equal(i);
      expect(userData.owner).to.equal(userPools[k++].user);
      expect(userData.token).to.equal(token);
      expect(userData.params).to.deep.equal(params);
    }
  }

  async function _logGasPrice(params: BigNumber[]) {
    const tx = await simpleBuilder.connect(projectOwner).buildMassPools(addressParams, userPools, params);
    const txReceipt = await tx.wait();
    const gasUsed = txReceipt.gasUsed;
    const GREEN_TEXT = '\x1b[32m';
    console.log(`${GREEN_TEXT}Gas Used: ${gasUsed.toString()}`);
    console.log(`Price per one pool: ${gasUsed.div(userPools.length)}`);
  }

  function _createProviderParams(provider: string) {
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
    simpleBuilder = await deployed('SimpleBuilder', lockDealNFT.address);
    await lockDealNFT.setApprovedProvider(lockProvider.address, true);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockDealNFT.address, true);
    await lockDealNFT.setApprovedProvider(simpleBuilder.address, true);
  });

  beforeEach(async () => {
    userPools = await _createUsers(amount, '4');
    addressParams = [timedProvider.address, token];
    startTime = ethers.BigNumber.from((await time.latest()) + ONE_DAY); // plus 1 day
    finishTime = startTime.add(7 * ONE_DAY); // plus 7 days from `startTime`
  });

  it('should create 10 dealProvider pools', async () => {
    const userCount = '10';
    const params = _createProviderParams(dealProvider.address);
    addressParams[0] = dealProvider.address;
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 50 dealProvider pools', async () => {
    const userCount = '50';
    const params = _createProviderParams(dealProvider.address);
    addressParams[0] = dealProvider.address;
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 100 dealProvider pools', async () => {
    const userCount = '100';
    const params = _createProviderParams(dealProvider.address);
    addressParams[0] = dealProvider.address;
    await _testMassPoolsData(dealProvider.address, amount, userCount, params);
  });

  it('should create 10 lockProvider pools', async () => {
    const userCount = '10';
    const params = _createProviderParams(lockProvider.address);
    addressParams[0] = lockProvider.address;
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 50 lockProvider pools', async () => {
    const userCount = '50';
    const params = _createProviderParams(lockProvider.address);
    addressParams[0] = lockProvider.address;
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 100 lockProvider pools', async () => {
    const userCount = '100';
    const params = _createProviderParams(lockProvider.address);
    addressParams[0] = lockProvider.address;
    await _testMassPoolsData(lockProvider.address, amount, userCount, params);
  });

  it('should create 10 timedProvider pools', async () => {
    const userCount = '10';
    const params = _createProviderParams(timedProvider.address);
    addressParams[0] = timedProvider.address;
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });

  it('should create 50 timedProvider pools', async () => {
    const userCount = '50';
    const params = _createProviderParams(timedProvider.address);
    addressParams[0] = timedProvider.address;
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });

  it('should create 100 timedProvider pools', async () => {
    const userCount = '100';
    const params = _createProviderParams(timedProvider.address);
    addressParams[0] = timedProvider.address;
    await _testMassPoolsData(timedProvider.address, amount, userCount, params);
  });
});
