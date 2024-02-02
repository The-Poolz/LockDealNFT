import { FeeLockProvider, FeeDealProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { deployed } from '../helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { BigNumber, Bytes } from 'ethers';
import { ethers } from 'hardhat';
import { ERC20Token } from '../../typechain-types';

describe('Fee Lock Provider', function () {
  let lockDealNFT: LockDealNFT;
  let feeLockProvider: FeeLockProvider;
  let mockVaultManager: MockVaultManager;
  let feeCollector: FeeCollector;
  let poolId: number;
  let collector: SignerWithAddress;
  let owner: SignerWithAddress;
  let startTime: number;
  let token: ERC20Token;
  let addresses: string[];
  let params: [BigNumber, number];
  let vaultId: BigNumber;
  const name: string = 'FeeLockProvider';
  const amount = ethers.utils.parseUnits('100', 18);
  const fee = '1000'; // 10%
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');

  before(async () => {
    [owner, collector] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', lockDealNFT.address);
    token = await deployed('ERC20Token', 'TestToken', 'TEST');
    const feeDealProvider: FeeDealProvider = await deployed(
      'FeeDealProvider',
      feeCollector.address,
      lockDealNFT.address,
    );
    feeLockProvider = await deployed('FeeLockProvider', lockDealNFT.address, feeDealProvider.address);
    await lockDealNFT.setApprovedContract(feeLockProvider.address, true);
    await lockDealNFT.setApprovedContract(feeCollector.address, true);
    await mockVaultManager.setTransferStatus(true);
    await token.approve(mockVaultManager.address, amount.mul(33));
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + 100;
    params = [amount, startTime];
    addresses = [owner.address, token.address];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    vaultId = await mockVaultManager.Id();
    await mockVaultManager.setVaultRoyalty(vaultId.add(1), collector.address, fee);
  });

  it("should return fee lock provider's name", async () => {
    expect(await feeLockProvider.name()).to.equal(name);
  });

  it('should create a new fee lock deal', async () => {
    await feeLockProvider.createNewPool(addresses, params, signature);
    vaultId = await mockVaultManager.Id();
    const data = await lockDealNFT.getData(poolId);
    expect(data).to.deep.equal([feeLockProvider.address, name, poolId, vaultId, owner.address, token.address, params]);
  });

  it('should revert withdraw from LockDealNFT', async () => {
    await feeLockProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, lockDealNFT.address, poolId),
    ).to.be.revertedWith('FeeDealProvider: fee not collected');
  });

  it('should withdraw with fee calculation', async () => {
    await feeLockProvider.createNewPool(addresses, params, signature);
    const beforeBalance = await token.balanceOf(owner.address);
    await time.setNextBlockTimestamp(startTime + 1);
    await lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, feeCollector.address, poolId);
    const afterBalance = await token.balanceOf(owner.address);
    expect(afterBalance).to.equal(beforeBalance.add(amount.sub(amount.div(10))));
  });
});
