import { FeeTimedProvider, FeeDealProvider, FeeLockProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager, ERC20Token } from '../../typechain-types';
import { deployed } from '../helper';
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
  let owner: SignerWithAddress;
  let collector: SignerWithAddress;
  let addresses: string[];
  let params: [BigNumber, number, number];
  let vaultId: BigNumber;
  let token: ERC20Token;
  const name: string = 'FeeTimedProvider';
  const amount = ethers.utils.parseUnits('100', 18);
  const fee = ethers.utils.parseUnits('1', 17); // 10%
  const ONE_DAY = 86400;
  let startTime: number, finishTime: number;
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');

  before(async () => {
    [owner, collector] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', fee.toString(), collector.address, lockDealNFT.address);
    feeDealProvider = await deployed('FeeDealProvider', feeCollector.address, lockDealNFT.address);
    feeLockProvider = await deployed('FeeLockProvider', lockDealNFT.address, feeDealProvider.address);
    token = await deployed('ERC20Token', 'TestToken', 'TEST');
    feeTimeProvider = await deployed('FeeTimedProvider', lockDealNFT.address, feeLockProvider.address);
    await lockDealNFT.setApprovedContract(feeDealProvider.address, true);
    await lockDealNFT.setApprovedContract(feeLockProvider.address, true);
    await lockDealNFT.setApprovedContract(feeTimeProvider.address, true);
    await lockDealNFT.setApprovedContract(feeCollector.address, true);
    await mockVaultManager.setTransferStatus(true);
    await token.approve(mockVaultManager.address, amount.mul(33));
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + ONE_DAY; // plus 1 day
    finishTime = startTime + 7 * ONE_DAY; // plus 7 days from `startTime`
    params = [amount, startTime, finishTime];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    addresses = [owner.address, token.address];
    vaultId = await mockVaultManager.Id();
  });

  it("should return fee timed provider's name", async () => {
    expect(await feeTimeProvider.name()).to.equal(name);
  });

  it('should create a new fee timed deal', async () => {
    await feeTimeProvider.createNewPool(addresses, params, signature);
    vaultId = await mockVaultManager.Id();
    const data = await lockDealNFT.getData(poolId);
    const expectedParams = [amount, startTime, finishTime, amount];
    expect(data).to.deep.equal([feeTimeProvider.address, name, poolId, vaultId, owner.address, token, expectedParams]);
  });

  it('should revert withdraw from LockDealNFT', async () => {
    await feeTimeProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, lockDealNFT.address, poolId),
    ).to.be.revertedWith('FeeDealProvider: fee not collected');
  });

  it('should withdraw with fee calculation', async () => {
    await feeTimeProvider.createNewPool(addresses, params, signature);
    const beforeBalance = await token.balanceOf(owner.address);
    await time.setNextBlockTimestamp(finishTime + 1);
    await lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, feeCollector.address, poolId);
    const afterBalance = await token.balanceOf(owner.address);
    expect(afterBalance).to.equal(beforeBalance.add(amount.sub(amount.div(10))));
  });
});
