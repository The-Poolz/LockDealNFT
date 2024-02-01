import { FeeLockProvider, FeeDealProvider, LockDealNFT, FeeCollector } from '../../typechain-types';
import { MockVaultManager } from '../../typechain-types';
import { deployed, token, MAX_RATIO } from '../helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { BigNumber, Bytes, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Fee Lock Provider', function () {
  let lockDealNFT: LockDealNFT;
  let feeLockProvider: FeeLockProvider;
  let mockVaultManager: MockVaultManager;
  let feeCollector: FeeCollector;
  let poolId: number;
  let receiver: SignerWithAddress;
  let newOwner: SignerWithAddress;
  let startTime: number;
  let addresses: string[];
  let params: [number, number];
  let vaultId: BigNumber;
  const name: string = 'FeeLockProvider';
  const amount = 10000;
  const fee = '100';
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');

  before(async () => {
    [receiver, newOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    feeCollector = await deployed('FeeCollector', fee, receiver.address, lockDealNFT.address);
    const feeDealProvider: FeeDealProvider = await deployed(
      'FeeDealProvider',
      feeCollector.address,
      lockDealNFT.address,
    );
    feeLockProvider = await deployed('FeeLockProvider', lockDealNFT.address, feeDealProvider.address);
    await lockDealNFT.setApprovedContract(feeLockProvider.address, true);
    await lockDealNFT.setApprovedContract(feeCollector.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + 100;
    params = [amount, startTime];
    addresses = [receiver.address, token];
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    vaultId = await mockVaultManager.Id();
  });

  it("should return fee lock provider's name", async () => {
    expect(await feeLockProvider.name()).to.equal(name);
  });

  it('should create a new fee lock deal', async () => {
    await feeLockProvider.createNewPool(addresses, params, signature);
    vaultId = await mockVaultManager.Id();
    const data = await lockDealNFT.getData(poolId);
    expect(data).to.deep.equal([feeLockProvider.address, name, poolId, vaultId, receiver.address, token, params]);
  });

  it('should revert withdraw from LockDealNFT', async () => {
    await feeLockProvider.createNewPool(addresses, params, signature);
    await expect(
      lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId),
    ).to.be.revertedWith('FeeDealProvider: fee not collected');
  });

  it("should withdraw fee to fee collector's address", async () => {});
});
