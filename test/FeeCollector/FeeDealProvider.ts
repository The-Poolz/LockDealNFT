import { FeeDealProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { DealProvider } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { deployed, token, MAX_RATIO } from '../helper';
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
  let receiver: SignerWithAddress;
  let newOwner: SignerWithAddress;
  let addresses: string[];
  let params: [number];
  let vaultId: BigNumber;
  const name: string = 'FeeDealProvider';
  const amount = 10000;
  const fee = '100';
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');

  before(async () => {
    [receiver, newOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', fee, receiver.address, lockDealNFT.address);
    feeDealProvider = await deployed('FeeDealProvider', feeCollector.address, lockDealNFT.address);
    await lockDealNFT.setApprovedContract(feeDealProvider.address, true);
    await lockDealNFT.setApprovedContract(feeCollector.address, true);
  });

  beforeEach(async () => {
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    params = [amount];
    addresses = [receiver.address, token];
  });

  it("should return fee deal provider's name", async () => {
    expect(await feeDealProvider.name()).to.equal(name);
  });

  it('should create a new fee deal', async () => {
    await feeDealProvider.createNewPool(addresses, params, signature);
    vaultId = await mockVaultManager.Id();
    const data = await lockDealNFT.getData(poolId);
    expect(data).to.deep.equal([feeDealProvider.address, name, poolId, vaultId, receiver.address, token, params]);
  });

  it('should revert withdraw from LockDealNFT', async () => {
    await feeDealProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId),
    ).to.be.revertedWith('FeeDealProvider: fee not collected');
  });

  it('should revert withdraw wrong fee provider', async () => {
    const nonFeeProvider: DealProvider = await deployed('DealProvider', lockDealNFT.address);
    await lockDealNFT.setApprovedContract(nonFeeProvider.address, true);
    await nonFeeProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, feeCollector.address, poolId),
    ).to.be.revertedWith('FeeCollectorProvider: wrong provider');
  });

  it("should withdraw fee to fee collector's address", async () => {});
});
