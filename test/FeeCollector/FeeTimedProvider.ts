import { FeeTimedProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { deployed, token, MAX_RATIO } from '../helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { BigNumber, Bytes, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Fee Timed Provider', function () {
  let lockDealNFT: LockDealNFT;
  let feeTimeProvider: FeeTimedProvider;
  let mockVaultManager: MockVaultManager;
  let feeCollector: FeeCollector;
  let poolId: number;
  let receiver: SignerWithAddress;
  let newOwner: SignerWithAddress;
  let addresses: string[];
  let params: [number, number, number];
  let vaultId: BigNumber;
  const name: string = 'FeeTimedProvider';
  const amount = 10000;
  const fee = '100';
  const ONE_DAY = 86400;
  let startTime: number, finishTime: number;
  let halfTime: number;
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');
  const ratio = MAX_RATIO.div(2); // half of the amount

  before(async () => {
    [receiver, newOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', fee, receiver.address, lockDealNFT.address);
    const feeTimeProviderAddress = await feeCollector.feeTimedProvider();
    feeTimeProvider = await ethers.getContractAt('FeeTimedProvider', feeTimeProviderAddress);
    const feeLockProvider = await feeCollector.feeLockProvider();
    await lockDealNFT.setApprovedContract(feeLockProvider, true);
    await lockDealNFT.setApprovedContract(feeTimeProvider.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
    params = [amount, startTime, finishTime];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    addresses = [receiver.address, token];
    vaultId = await mockVaultManager.Id();
    halfTime = (finishTime - startTime) / 2;
  });

  it("should return fee timed provider's name", async () => {
    expect(await feeTimeProvider.name()).to.equal(name);
  });

  it('should create a new fee timed deal', async () => {
    await feeTimeProvider.createNewPool(addresses, params, signature);
    vaultId = await mockVaultManager.Id();
    const data = await lockDealNFT.getData(poolId);
    const expectedParams = [amount, startTime, finishTime, amount];
    expect(data).to.deep.equal([
      feeTimeProvider.address,
      name,
      poolId,
      vaultId,
      receiver.address,
      token,
      expectedParams,
    ]);
  });

  it('should revert withdraw from LockDealNFT', async () => {
    await feeTimeProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId),
    ).to.be.revertedWith('FeeDealProvider: fee not collected');
  });
});
