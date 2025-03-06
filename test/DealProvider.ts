import { LockDealNFT } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { MockVaultManager } from '../typechain-types';
import { deployed, token, MAX_RATIO } from './helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Bytes, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('Deal Provider', function () {
  let dealProvider: DealProvider;
  let lockDealNFT: LockDealNFT;
  let mockVaultManager: MockVaultManager;
  let poolId: number;
  let receiver: SignerWithAddress;
  let newOwner: SignerWithAddress;
  let addresses: string[];
  let params: [number];
  let vaultId: BigNumber;
  const name: string = 'DealProvider';
  const amount = 10000;
  const signature: Bytes = ethers.utils.toUtf8Bytes('signature');
  const ratio = MAX_RATIO.div(2); // half of the amount

  before(async () => {
    [receiver, newOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    await lockDealNFT.setApprovedContract(dealProvider.address, true);
  });

  beforeEach(async () => {
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    params = [amount];
    addresses = [receiver.address, token];
    await dealProvider.createNewPool(addresses, params, signature);
    vaultId = await mockVaultManager.Id();
  });

  it('should return provider name', async () => {
    expect(await dealProvider.name()).to.equal('DealProvider');
  });

  it('should get pool data', async () => {
    const poolData = await lockDealNFT.getData(poolId);
    const params = [amount];
    expect(poolData).to.deep.equal([dealProvider.address, name, poolId, vaultId, receiver.address, token, params]);
  });

  it('should check pool creation events', async () => {
    const tx = await dealProvider.createNewPool(addresses, params, signature);
    await tx.wait();
    const events = await dealProvider.queryFilter(dealProvider.filters.UpdateParams());
    expect(events[events.length - 1].args.poolId).to.equal(poolId + 1);
    expect(events[events.length - 1].args.params[0]).to.equal(amount); //assuming amount is at index 0 in the params array
  });

  it('should revert zero owner address', async () => {
    addresses[1] = constants.AddressZero;
    await expect(dealProvider.createNewPool(addresses, params, signature)).to.be.revertedWith(
      'Zero Address is not allowed',
    );
  });

  it('should revert zero token address', async () => {
    addresses[0] = constants.AddressZero;
    await expect(dealProvider.createNewPool(addresses, params, signature)).to.be.revertedWith(
      'Zero Address is not allowed',
    );
  });

  it('should revert zero params', async () => {
    await expect(dealProvider.createNewPool(addresses, [], signature)).to.be.revertedWith('invalid params length');
  });

  describe('Split Amount', () => {
    it('should check data in old pool after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, receiver.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount / 2];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([dealProvider.address, name, poolId, vaultId, receiver.address, token, params]);
    });

    it('should check data in new pool after split', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount / 2];
      const poolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData).to.deep.equal([
        dealProvider.address,
        name,
        poolId + 1,
        vaultId,
        newOwner.address,
        token,
        params,
      ]);
    });

    it('should check data in new pool after selfSplit', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256'], [ratio]);
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      const params = [amount / 2];
      const poolData = await lockDealNFT.getData(poolId + 1);
      expect(poolData).to.deep.equal([
        dealProvider.address,
        name,
        poolId + 1,
        vaultId,
        receiver.address,
        token,
        params,
      ]);
    });

    it('should return split metadata event', async () => {
      const packedData = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [ratio, newOwner.address]);
      const tx = await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData);
      await tx.wait();
      const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MetadataUpdate());
      expect(events[events.length - 1].args._tokenId).to.equal(poolId);
    });
  });

  describe('Deal Withdraw', () => {
    it('should check data in pool after withdraw', async () => {
      await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      const params = [0];
      const poolData = await lockDealNFT.getData(poolId);
      expect(poolData).to.deep.equal([dealProvider.address, name, poolId, vaultId, lockDealNFT.address, token, params]);
    });

    it('should check events after withdraw', async () => {
      poolId = (await lockDealNFT.totalSupply()).toNumber() - 1;

      const tx = await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      await tx.wait();
      const events = await lockDealNFT.queryFilter(lockDealNFT.filters.TokenWithdrawn());
      expect(events[events.length - 1].args.poolId.toString()).to.equal(poolId.toString());
      expect(events[events.length - 1].args.owner.toString()).to.equal(receiver.address.toString());
      expect(events[events.length - 1].args.withdrawnAmount.toString()).to.equal(amount.toString());
      expect(events[events.length - 1].args.leftAmount.toString()).to.equal('0'.toString());
    });

    it('getWithdrawableAmount should get all amount', async () => {
      const withdrawableAmount = await dealProvider.getWithdrawableAmount(poolId);
      expect(withdrawableAmount).to.equal(amount);
    });

    it('should return withdraw metadata event', async () => {
      const tx = await lockDealNFT
        .connect(receiver)
        ['safeTransferFrom(address,address,uint256)'](receiver.address, lockDealNFT.address, poolId);
      await tx.wait();
      const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MetadataUpdate());
      expect(events[events.length - 1].args._tokenId).to.equal(poolId);
    });
  });
});
