import { FeeDealProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { deployed, token, MAX_RATIO } from '../helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Bytes, constants } from 'ethers';
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
  const ratio = MAX_RATIO.div(2); // half of the amount

  before(async () => {
    [receiver, newOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', fee, receiver.address, lockDealNFT.address);
    const feeDealProviderAddress = await feeCollector.feeDealProvider();
    feeDealProvider = await ethers.getContractAt('FeeDealProvider', feeDealProviderAddress);
    await lockDealNFT.setApprovedContract(feeDealProvider.address, true);
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
});
