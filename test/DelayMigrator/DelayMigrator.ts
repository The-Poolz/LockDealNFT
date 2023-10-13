import { MockVaultManager } from '../../typechain-types';
import { DealProvider } from '../../typechain-types';
import { LockDealNFT } from '../../typechain-types';
import { LockDealProvider } from '../../typechain-types';
import { TimedDealProvider } from '../../typechain-types';
import { MockProvider } from '../../typechain-types';
import { DelayVaultMigrator } from '../../typechain-types';
import { MockDelayVault } from '../../typechain-types/contracts/mock/MockDelayVault';
import { deployed, token, BUSD, MAX_RATIO } from '../helper';
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
  let params: [BigNumber, number, number, BigNumber, BigNumber, number];
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
    delayVaultMigrator = await deployed('DelayVaultMigrator', mockDelayVault.address);
    await lockDealNFT.setApprovedContract(lockProvider.address, true);
    await lockDealNFT.setApprovedContract(dealProvider.address, true);
    await lockDealNFT.setApprovedContract(timedProvider.address, true);
    await lockDealNFT.setApprovedContract(lockDealNFT.address, true);
  });

  beforeEach(async () => {});

  it('should finilize data', async () => {
    
  });
});
