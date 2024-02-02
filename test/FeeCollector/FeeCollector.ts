import { FeeTimedProvider, FeeDealProvider, FeeLockProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager, DealProvider, ERC20Token } from '../../typechain-types';
import { deployed } from '../helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { BigNumber, Bytes } from 'ethers';
import { ethers } from 'hardhat';

describe('Fee Collector', function () {
  let lockDealNFT: LockDealNFT;
  let feeDealProvider: FeeDealProvider;
  let feeLockProvider: FeeLockProvider;
  let feeTimeProvider: FeeTimedProvider;
  let mockVaultManager: MockVaultManager;
  let feeCollector: FeeCollector;
  let poolId: number;
  let collector: SignerWithAddress;
  let owner: SignerWithAddress;
  let addresses: string[];
  let params: [BigNumber, number, number];
  let token: ERC20Token;
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
  });

  it('should revert withdraw wrong fee provider', async () => {
    const nonFeeProvider: DealProvider = await deployed('DealProvider', lockDealNFT.address);
    await lockDealNFT.setApprovedContract(nonFeeProvider.address, true);
    await nonFeeProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, feeCollector.address, poolId),
    ).to.be.revertedWith('FeeCollector: wrong provider');
  });

  it("should withdraw fee to fee collector's address from feeDealProvider", async () => {
    await feeDealProvider.createNewPool(addresses, params, signature);
    await lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, feeCollector.address, poolId);
    expect(await token.balanceOf(collector.address)).to.equal(amount.div(10));
  });

  it("should withdraw fee to fee collector's address from feeLockProvider", async () => {
    await feeLockProvider.createNewPool(addresses, params, signature);
    await time.setNextBlockTimestamp(startTime + 1);
    const beforeBalance = await token.balanceOf(collector.address);
    await lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, feeCollector.address, poolId);
    const afterBalance = await token.balanceOf(collector.address);
    expect(afterBalance).to.equal(beforeBalance.add(amount.div(10)));
  });

  it("should withdraw fee to fee collector's address from feeTimeProvider", async () => {
    await feeTimeProvider.createNewPool(addresses, params, signature);
    await time.setNextBlockTimestamp(finishTime + 1);
    const beforeBalance = await token.balanceOf(collector.address);
    await lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, feeCollector.address, poolId);
    const afterBalance = await token.balanceOf(collector.address);
    expect(afterBalance).to.equal(beforeBalance.add(amount.div(10)));
  });
});
