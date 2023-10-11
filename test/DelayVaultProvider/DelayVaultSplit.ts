import { MAX_RATIO } from '../helper';
import { delayVault } from './setupTests';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

describe('delayVault split', async () => {
  before(async () => {
    await delayVault.initialize();
  });

  beforeEach(async () => {
    delayVault.poolId = await delayVault.lockDealNFT.totalSupply();
  });

  async function split(creator: SignerWithAddress, userToSplit: SignerWithAddress, params: BigNumber[]) {
    await delayVault.delayVaultProvider.connect(creator).createNewDelayVault(creator.address, params);
    const bytes = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [delayVault.ratio, creator.address]);
    await delayVault.lockDealNFT
      .connect(creator)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        userToSplit.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
        bytes,
      );
  }

  it('should return half amount in old pool after split', async () => {
    await split(delayVault.user4, delayVault.user4, [delayVault.tier1]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId);
    expect(data.owner).to.equal(delayVault.user4.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier1.div(2)]);
  });

  it('should create new delay nft after split with first tier', async () => {
    await split(delayVault.user3, delayVault.user3, [delayVault.tier1]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier1.div(2)]);
  });

  it('should create new delay nft after split with second tier', async () => {
    await split(delayVault.user3, delayVault.user3, [delayVault.tier2]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier2.div(2)]);
  });

  it('should create new delay nft after split with third tier', async () => {
    await split(delayVault.user3, delayVault.user3, [delayVault.tier3]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier3.div(2)]);
  });

  it('the level should not decrease after split', async () => {
    const params = [delayVault.tier2];
    const owner = delayVault.newOwner;
    await delayVault.delayVaultProvider.connect(owner).createNewDelayVault(owner.address, params);
    expect(await delayVault.delayVaultProvider.userToType(owner.address)).to.equal(1);
    const rate = MAX_RATIO.sub(MAX_RATIO.div(10)); // 90%
    const bytes = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [rate, delayVault.user3.address]);
    let newAmount = await delayVault.delayVaultProvider.userToAmount(owner.address);
    await delayVault.lockDealNFT
      .connect(owner)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        owner.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
        bytes,
      );
    newAmount = await delayVault.delayVaultProvider.userToAmount(owner.address);
    expect(await delayVault.delayVaultProvider.userToType(owner.address)).to.equal(1);
  });

  it("can't upgrade type another user tier by using split", async () => {
    expect(await delayVault.delayVaultProvider.userToType(delayVault.receiver.address)).to.equal(0);
    const params = [delayVault.tier2];
    const owner = delayVault.newOwner;
    await delayVault.delayVaultProvider.connect(owner).createNewDelayVault(owner.address, params);
    const bytes = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [MAX_RATIO, delayVault.receiver.address]);
    await expect(
      delayVault.lockDealNFT
        .connect(owner)
        ['safeTransferFrom(address,address,uint256,bytes)'](
          owner.address,
          delayVault.lockDealNFT.address,
          delayVault.poolId,
          bytes,
        ),
    ).to.be.revertedWith('type must be the same or lower');
  });
});
