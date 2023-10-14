import { LockDealProvider } from '../../typechain-types';
import { TimedDealProvider } from '../../typechain-types';
import { LockDealNFT } from '../../typechain-types';
import { DealProvider } from '../../typechain-types';
import { MockProvider } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { DelayVaultProvider } from '../../typechain-types';
import { DelayVaultMigrator } from '../../typechain-types';
import { MockDelayVault } from '../../typechain-types';
import { IDelayVaultData } from '../../typechain-types/contracts/AdvancedProviders/DelayVaultProvider/DelayVaultProvider';
import { deployed, token, MAX_RATIO, _createUsers, gasLimit } from '../helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

export class DelayVault {
  public delayVaultProvider!: DelayVaultProvider;
  public lockDealNFT!: LockDealNFT;
  public timedDealProvider!: TimedDealProvider;
  public lockProvider!: LockDealProvider;
  public delayVaultMigrator!: DelayVaultMigrator;
  public mockDelayVault!: MockDelayVault;
  public dealProvider!: DealProvider;
  public mockProvider!: MockProvider;
  public mockVaultManager!: MockVaultManager;
  public poolId!: BigNumber;
  public vaultId!: BigNumber;
  public receiver!: SignerWithAddress;
  public user1!: SignerWithAddress;
  public user2!: SignerWithAddress;
  public user3!: SignerWithAddress;
  public user4!: SignerWithAddress;
  public newOwner!: SignerWithAddress;
  public startTime!: number;
  public finishTime!: number;
  public providerData!: IDelayVaultData.ProviderDataStruct[];
  public tier1: BigNumber = ethers.BigNumber.from(250);
  public tier2: BigNumber = ethers.BigNumber.from(3500);
  public tier3: BigNumber = ethers.BigNumber.from(20000);
  public ratio: BigNumber = MAX_RATIO.div(2);

  async initialize() {
    [this.receiver, this.newOwner, this.user1, this.user2, this.user3, this.user4] = await ethers.getSigners();
    this.mockVaultManager = await deployed('MockVaultManager');
    this.lockDealNFT = await deployed('LockDealNFT', this.mockVaultManager.address, '');
    this.dealProvider = await deployed('DealProvider', this.lockDealNFT.address);
    this.lockProvider = await deployed('LockDealProvider', this.lockDealNFT.address, this.dealProvider.address);
    this.timedDealProvider = await deployed('TimedDealProvider', this.lockDealNFT.address, this.lockProvider.address);
    this.mockProvider = await deployed('MockProvider', this.lockDealNFT.address, this.timedDealProvider.address);
    const mockDelay = await ethers.getContractFactory('MockDelayVault');
    this.mockDelayVault = await mockDelay.deploy(token, [], []);
    this.delayVaultMigrator = await deployed('DelayVaultMigrator', this.lockDealNFT.address, this.mockDelayVault.address);
    const DelayVaultProvider = await ethers.getContractFactory('DelayVaultProvider');
    const ONE_DAY = 86400;
    const week = ONE_DAY * 7;
    this.startTime = week;
    this.finishTime = week * 4;
    this.providerData = [
      { provider: this.dealProvider.address, params: [], limit: this.tier1 },
      { provider: this.lockProvider.address, params: [this.startTime], limit: this.tier2 },
      { provider: this.timedDealProvider.address, params: [this.startTime, this.finishTime], limit: this.tier3 },
    ];
    this.delayVaultProvider = await DelayVaultProvider.deploy(
      token,
      this.delayVaultMigrator.address,
      this.providerData,
      {
        gasLimit: gasLimit,
      },
    );
    await this.lockDealNFT.setApprovedContract(this.dealProvider.address, true);
    await this.lockDealNFT.setApprovedContract(this.lockProvider.address, true);
    await this.lockDealNFT.setApprovedContract(this.timedDealProvider.address, true);
    await this.lockDealNFT.setApprovedContract(this.mockProvider.address, true);
    await this.lockDealNFT.setApprovedContract(this.delayVaultProvider.address, true);
  }
}

export const delayVault = new DelayVault();
