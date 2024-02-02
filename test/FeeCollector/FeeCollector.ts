import { FeeTimedProvider, FeeDealProvider, FeeLockProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { deployed, token } from '../helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { BigNumber, Bytes } from 'ethers';
import { ethers } from 'hardhat';

describe('Fee Timed Provider', function () {
  let lockDealNFT: LockDealNFT;
  let feeDealProvider: FeeDealProvider;
  let feeLockProvider: FeeLockProvider;
  let feeTimeProvider: FeeTimedProvider;
  let mockVaultManager: MockVaultManager;
  let feeCollector: FeeCollector;
  let poolId: number;
  let receiver: SignerWithAddress;
  let addresses: string[];
  let params: [number, number, number];
  let vaultId: BigNumber;
  const amount = 10000;
  const fee = '100';
  const ONE_DAY = 86400;
  let startTime: number, finishTime: number;
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');

  before(async () => {
    [receiver] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', fee, receiver.address, lockDealNFT.address);
    const feeDealProvider: FeeDealProvider = await deployed(
      'FeeDealProvider',
      feeCollector.address,
      lockDealNFT.address,
    );
    const feeLockProvider: FeeLockProvider = await deployed(
      'FeeLockProvider',
      lockDealNFT.address,
      feeDealProvider.address,
    );
    feeTimeProvider = await deployed('FeeTimedProvider', lockDealNFT.address, feeLockProvider.address);
    await lockDealNFT.setApprovedContract(feeLockProvider.address, true);
    await lockDealNFT.setApprovedContract(feeTimeProvider.address, true);
    await lockDealNFT.setApprovedContract(feeCollector.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
    params = [amount, startTime, finishTime];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    addresses = [receiver.address, token];
    vaultId = await mockVaultManager.Id();
  });

  it('should revert withdraw from LockDealNFT by using fee timed provider', async () => {
    await feeTimeProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId),
    ).to.be.revertedWith('FeeDealProvider: fee not collected');
  });
});
