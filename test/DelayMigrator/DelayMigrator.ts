import { MockVaultManager } from '../../typechain-types';
import { DealProvider } from '../../typechain-types';
import { LockDealNFT } from '../../typechain-types';
import { LockDealProvider } from '../../typechain-types';
import { TimedDealProvider } from '../../typechain-types';
import { MockProvider } from '../../typechain-types';
import { DelayVaultMigrator } from '../../typechain-types';
import { DelayVaultProvider } from '../../typechain-types/contracts/AdvancedProviders/DelayVaultProvider';
import { IDelayVaultProvider } from '../../typechain-types/contracts/interfaces/IDelayVaultProvider';
import { MockDelayVault } from '../../typechain-types/contracts/mock/MockDelayVault';
import { deployed, token, BUSD, MAX_RATIO, gasLimit } from '../helper';
import { time, mine } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Delay Migrator tests', function () {
  let lockProvider: LockDealProvider;
  let dealProvider: DealProvider;
  let timedProvider: TimedDealProvider;
  let mockVaultManager: MockVaultManager;
  let mockDelayVault: MockDelayVault;
  let delayVaultMigrator: DelayVaultMigrator;
  let delayVaultProvider: DelayVaultProvider;
  let halfTime: number;
  const rate = ethers.utils.parseUnits('0.1', 21);
  const mainCoinAmount = ethers.utils.parseEther('10');
  let lockDealNFT: LockDealNFT;
  let poolId: number;
  let vaultId: BigNumber;
  let receiver: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;
  let projectOwner: SignerWithAddress;
  let addresses: string[];
  let providerData: IDelayVaultProvider.ProviderDataStruct[];
  let params: [BigNumber, number, number, BigNumber, BigNumber, number];
  const tier1: BigNumber = ethers.BigNumber.from(250);
  const tier2: BigNumber = ethers.BigNumber.from(3500);
  const tier3: BigNumber = ethers.BigNumber.from(20000);
  let startTime: number, finishTime: number;
  const amount = ethers.utils.parseEther('100');
  const ONE_DAY = 86400;
  const userVaults: MockDelayVault.VaultStruct[] = [
    {
      Amount: amount,
      StartDelay: ONE_DAY,
      CliffDelay: 0,
      FinishDelay: 0,
    },
    {
      Amount: amount.mul(2),
      StartDelay: 0,
      CliffDelay: 0,
      FinishDelay: ONE_DAY,
    },
    {
      Amount: amount.div(2),
      StartDelay: 0,
      CliffDelay: ONE_DAY,
      FinishDelay: 0,
    },
  ];

  before(async () => {
    [receiver, projectOwner, user1, user2, user3] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    timedProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
    const mockDelay = await ethers.getContractFactory('MockDelayVault');
    mockDelayVault = await mockDelay.deploy(token, userVaults, [user1.address, user2.address, user3.address]);
    delayVaultMigrator = await deployed('DelayVaultMigrator', lockDealNFT.address, mockDelayVault.address);
    const week = ONE_DAY * 7;
    startTime = week;
    finishTime = week * 4;
    providerData = [
      { provider: dealProvider.address, params: [], limit: tier1 },
      { provider: lockProvider.address, params: [startTime], limit: tier2 },
      { provider: timedProvider.address, params: [startTime, finishTime], limit: tier3 },
    ];
    const DelayVaultProvider = await ethers.getContractFactory('DelayVaultProvider');
    delayVaultProvider = await DelayVaultProvider.deploy(token, delayVaultMigrator.address, providerData);
    await lockDealNFT.setApprovedContract(lockProvider.address, true);
    await lockDealNFT.setApprovedContract(dealProvider.address, true);
    await lockDealNFT.setApprovedContract(timedProvider.address, true);
    await lockDealNFT.setApprovedContract(lockDealNFT.address, true);
    await lockDealNFT.setApprovedContract(delayVaultProvider.address, true);
  });
  
  it('should revert invalid delayVaultProvider', async () => {
    await expect(delayVaultMigrator.finilize(mockDelayVault.address)).to.be.revertedWith(
      'DelayVaultMigrator: Invalid new delay vault contract',
    );
  });

  it('should revert invalid owner call', async () => {
    await expect(delayVaultMigrator.connect(user1).finilize(delayVaultProvider.address)).to.be.revertedWith(
      'DelayVaultMigrator: not owner',
    );
  });

  it('should revert not initialized migrate call', async () => {
    delayVaultMigrator = await deployed('DelayVaultMigrator', lockDealNFT.address, mockDelayVault.address);
    await expect(delayVaultMigrator.fullMigrate()).to.be.revertedWith('DelayVaultMigrator: not initialized');
  });

  it('should finilize data', async () => {
    await delayVaultMigrator.finilize(delayVaultProvider.address);
    expect(await delayVaultMigrator.newVault()).to.be.equal(delayVaultProvider.address);
    expect(await delayVaultMigrator.token()).to.be.equal(token);
    expect(await delayVaultMigrator.vaultManager()).to.be.equal(mockVaultManager.address);
    expect(await delayVaultMigrator.owner()).to.be.equal(constants.AddressZero);
  });

  it('should revert not approved migrate call', async () => {
    await expect(delayVaultMigrator.fullMigrate()).to.be.revertedWith('DelayVaultMigrator: not allowed');
  });

  it('should revert not approved withdrawTokensFromV1Vault call', async () => {
    await expect(delayVaultMigrator.withdrawTokensFromV1Vault()).to.be.revertedWith('DelayVaultMigrator: not allowed');
  });

  it('should revert not DelayVaultV1 CreateNewPool call', async () => {
    await expect(delayVaultMigrator.CreateNewPool(token, 0, 0, 0, 0, user1.address)).to.be.revertedWith(
      'DelayVaultMigrator: not DelayVaultV1',
    );
  });
});
