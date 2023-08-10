import { LockDealNFT } from '../typechain-types';
import { DealProvider } from '../typechain-types';
import { LockDealProvider } from '../typechain-types';
import { TimedDealProvider } from '../typechain-types';
import { MockVaultManager } from '../typechain-types';
import { deployed, token } from './helper';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe('LockDealNFT', function () {
  let lockDealNFT: LockDealNFT;
  let poolId: number;
  let mockVaultManager: MockVaultManager;
  let dealProvider: DealProvider;
  let lockDealProvider: LockDealProvider;
  let timedDealProvider: TimedDealProvider;
  let receiver: SignerWithAddress;
  let notOwner: SignerWithAddress;
  let vaultId: BigNumber;
  let startTime: number, finishTime: number;
  const amount: string = '1000';

  before(async () => {
    [receiver, notOwner] = await ethers.getSigners();
    mockVaultManager = await deployed('MockVaultManager');
    lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
    dealProvider = await deployed('DealProvider', lockDealNFT.address);
    lockDealProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
    timedDealProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockDealProvider.address);
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await lockDealNFT.setApprovedProvider(lockDealProvider.address, true);
    await lockDealNFT.setApprovedProvider(timedDealProvider.address, true);
    await lockDealNFT.setApprovedProvider(mockVaultManager.address, true);
  });

  beforeEach(async () => {
    startTime = (await time.latest()) + 100;
    finishTime = startTime + 100;
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    await dealProvider.createNewPool(receiver.address, token, [amount]);
    vaultId = await mockVaultManager.Id();
  });

  it('check NFT name', async () => {
    expect(await lockDealNFT.name()).to.equal('LockDealNFT');
  });

  it('check NFT symbol', async () => {
    expect(await lockDealNFT.symbol()).to.equal('LDNFT');
  });

  it('should set provider address', async () => {
    await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    expect(await lockDealNFT.approvedProviders(dealProvider.address)).to.be.true;
  });

  it('should return ProviderApproved event', async () => {
    const tx = await lockDealNFT.setApprovedProvider(dealProvider.address, true);
    await tx.wait();
    const events = await lockDealNFT.queryFilter(lockDealNFT.filters.ProviderApproved());
    expect(events[events.length - 1].args.status).to.equal(true);
    expect(events[events.length - 1].args.provider).to.equal(dealProvider.address);
  });

  it('should mint new token', async () => {
    expect(await lockDealNFT.totalSupply()).to.equal(poolId + 1);
  });

  it('should allow owner to transfer token', async () => {
    const initialOwner = receiver;
    const newOwner = notOwner;
    const tokenId = poolId; // Assuming the token ID is the pool ID

    // Ensure initialOwner owns the token
    expect(await lockDealNFT.ownerOf(tokenId)).to.equal(initialOwner.address);

    // Transfer the token
    await lockDealNFT.connect(initialOwner).transferFrom(initialOwner.address, newOwner.address, tokenId);

    // Check new owner
    expect(await lockDealNFT.ownerOf(tokenId)).to.equal(newOwner.address);
  });

  it('should not allow non-owner and non-approved address to transfer token', async () => {
    const initialOwner = receiver;
    const newOwner = notOwner;
    const anotherAddress = notOwner; // or another signer
    const tokenId = poolId;

    // Try to transfer the token without any approval. This should fail.
    await expect(
      lockDealNFT.connect(anotherAddress).transferFrom(initialOwner.address, newOwner.address, tokenId),
    ).to.be.revertedWith('ERC721: transfer caller is not owner nor approved');
  });

  it('should set provider', async () => {
    expect(await lockDealNFT.poolIdToProvider(poolId)).to.equal(dealProvider.address);
  });

  it('should return mintInitiated event', async () => {
    const tx = await dealProvider.createNewPool(receiver.address, token, [amount]);
    await tx.wait();
    const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MintInitiated());
    expect(events[events.length - 1].args.provider).to.equal(dealProvider.address);
  });

  it('should save provider address', async () => {
    expect(await lockDealNFT.poolIdToProvider(poolId)).to.equal(dealProvider.address);
  });

  it('only provider can mintAndTransfer', async () => {
    await expect(
      lockDealNFT
        .connect(notOwner)
        .mintAndTransfer(receiver.address, notOwner.address, token, 10, dealProvider.address),
    ).to.be.revertedWith('Provider not approved');
  });

  it('only provider can mintForProvider', async () => {
    await expect(
      lockDealNFT.connect(notOwner).mintForProvider(receiver.address, dealProvider.address),
    ).to.be.revertedWith('Provider not approved');
  });

  it('should return data from DealProvider using LockedDealNFT', async () => {
    const poolData = await lockDealNFT.getData(poolId);
    const params = [amount];
    expect(poolData).to.deep.equal([dealProvider.address, poolId, vaultId, receiver.address, token, params]);
  });

  it('should return data from LockDealProvider using LockedDealNFT', async () => {
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    const params = [amount, startTime];
    await lockDealProvider.createNewPool(receiver.address, token, params);
    const vaultId = await mockVaultManager.Id();
    const poolData = await lockDealNFT.getData(poolId);
    expect(poolData).to.deep.equal([lockDealProvider.address, poolId, vaultId, receiver.address, token, params]);
  });

  it('should return data from TimedDealProvider using LockedDealNFT', async () => {
    poolId = (await lockDealNFT.totalSupply()).toNumber();
    const params = [amount, startTime, finishTime, amount];
    await timedDealProvider.createNewPool(receiver.address, token, params);
    const vaultId = await mockVaultManager.Id();
    const poolData = await lockDealNFT.getData(poolId);
    expect(poolData).to.deep.equal([timedDealProvider.address, poolId, vaultId, receiver.address, token, params]);
  });

  it('should set baseURI', async () => {
    const baseURI = 'https://poolz.finance/';
    await lockDealNFT.setBaseURI(baseURI);
    expect(await lockDealNFT.baseURI()).to.equal(baseURI);
  });

  it('should revert set baseURI for not owner', async () => {
    const baseURI = 'https://notOwner.finance/';
    await expect(lockDealNFT.connect(notOwner).setBaseURI(baseURI)).to.be.revertedWith(
      'Ownable: caller is not the owner',
    );
  });

  it('should revert the same baseURI', async () => {
    const baseURI = await lockDealNFT.baseURI();
    await expect(lockDealNFT.setBaseURI(baseURI)).to.be.revertedWith("can't set the same baseURI");
  });

  it('should return tokenURI', async () => {
    const baseURI = await lockDealNFT.baseURI();
    expect(await lockDealNFT.tokenURI(poolId)).to.equal(baseURI + poolId.toString());
  });

  it('should return tokenURI event', async () => {
    const oldBaseURI = await lockDealNFT.baseURI();
    const baseURI = 'https://nft.poolz.finance/test/metadata/';
    const tx = await lockDealNFT.setBaseURI(baseURI);
    await tx.wait();
    const events = await lockDealNFT.queryFilter(lockDealNFT.filters.BaseURIChanged());
    expect(events[events.length - 1].args.oldBaseURI).to.equal(oldBaseURI);
    expect(events[events.length - 1].args.newBaseURI).to.equal(baseURI);
  });

  it('should revert not pool owner split call', async () => {
    const packedData = ethers.utils.defaultAbiCoder.encode(['uint256'], [1]);
    await expect(
      lockDealNFT
        .connect(notOwner)
        ['safeTransferFrom(address,address,uint256,bytes)'](receiver.address, lockDealNFT.address, poolId, packedData),
    ).to.be.revertedWith('ERC721: caller is not token owner or approved');
  });

  it('should refresh all metadata', async () => {
    const tx = await lockDealNFT.updateAllMetadata();
    await tx.wait();
    const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MetadataUpdate());
    expect(events[events.length - 1].args._tokenId).to.equal(constants.MaxUint256);
  });

  it('check if the contract supports IERC2981 interface', async () => {
    expect(await lockDealNFT.supportsInterface('0x2a55205a')).to.equal(true);
  });

  it('check if the contract supports IERC165 interface', async () => {
    expect(await lockDealNFT.supportsInterface('0x01ffc9a7')).to.equal(true);
  });

  it('check if the contract supports IERC721 interface', async () => {
    expect(await lockDealNFT.supportsInterface('0x80ac58cd')).to.equal(true);
  });

  it('check if the contract supports IERC721Enumerable interface', async () => {
    expect(await lockDealNFT.supportsInterface('0x780e9d63')).to.equal(true);
  });

  it('check if the contract supports IERC721Metadata interface', async () => {
    expect(await lockDealNFT.supportsInterface('0x5b5e139f')).to.equal(true);
  });

  xit('check if the contract supports ILockDealNFT interface', async () => {
    expect(await lockDealNFT.supportsInterface('0xd9677f13')).to.equal(true);
  });

  it('shuld return royalty', async () => {
    const royalty = await lockDealNFT.royaltyInfo(0, 100);
    expect(royalty).to.lengthOf(2);
  });
});
