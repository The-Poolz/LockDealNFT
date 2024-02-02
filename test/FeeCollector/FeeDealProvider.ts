import { FeeDealProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { deployed } from '../helper';
import { ERC20Token } from '../../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Bytes } from 'ethers';
import { ethers } from 'hardhat';

describe('Fee Deal Provider', function () {
  let lockDealNFT: LockDealNFT;
  let feeDealProvider: FeeDealProvider;
  let mockVaultManager: MockVaultManager;
  let feeCollector: FeeCollector;
  let poolId: number;
  let collector: SignerWithAddress;
  let owner: SignerWithAddress;
  let addresses: string[];
  let params: [BigNumber];
  let vaultId: BigNumber;
  let token: ERC20Token;
  const name: string = 'FeeDealProvider';
  const amount = ethers.utils.parseUnits('100', 18);
  const fee = ethers.utils.parseUnits('1', 17); // 10%
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');

  before(async () => {
    [owner, collector] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', fee.toString(), collector.address, lockDealNFT.address);
    feeDealProvider = await deployed('FeeDealProvider', feeCollector.address, lockDealNFT.address);
    token = await deployed('ERC20Token', 'TestToken', 'TEST');
    await lockDealNFT.setApprovedContract(feeDealProvider.address, true);
    await lockDealNFT.setApprovedContract(feeCollector.address, true);
    await mockVaultManager.setTransferStatus(true);
    await token.approve(mockVaultManager.address, amount.mul(33));
  });

  beforeEach(async () => {
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    params = [amount];
    addresses = [owner.address, token.address];
  });

  it("should return fee deal provider's name", async () => {
    expect(await feeDealProvider.name()).to.equal(name);
  });

  it('should create a new fee deal', async () => {
    await feeDealProvider.createNewPool(addresses, params, signature);
    vaultId = await mockVaultManager.Id();
    const data = await lockDealNFT.getData(poolId);
    expect(data).to.deep.equal([feeDealProvider.address, name, poolId, vaultId, owner.address, token.address, params]);
  });

  it('should revert withdraw from LockDealNFT', async () => {
    await feeDealProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, lockDealNFT.address, poolId),
    ).to.be.revertedWith('FeeDealProvider: fee not collected');
  });

  it('should withdraw with fee calculation', async () => {
    await feeDealProvider.createNewPool(addresses, params, signature);
    const beforeBalance = await token.balanceOf(owner.address);
    await lockDealNFT['safeTransferFrom(address,address,uint256)'](owner.address, feeCollector.address, poolId);
    const afterBalance = await token.balanceOf(owner.address);
    expect(afterBalance).to.equal(beforeBalance.add(amount.sub(amount.div(10))));
  });
});
