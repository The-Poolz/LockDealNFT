import { _createUsers } from '../helper';
import { delayVault } from './setupTests';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('delayVault split', async () => {
  before(async () => {
    await delayVault.initialize();
  });

  beforeEach(async () => {
    delayVault.poolId = await delayVault.lockDealNFT.totalSupply();
  });

  it('should return half amount in old pool after split', async () => {
    const params = [delayVault.tier1];
    const packedData = ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'address'],
      [delayVault.ratio, delayVault.user4.address],
    );
    await delayVault.delayVaultProvider.connect(delayVault.user4).createNewDelayVault(delayVault.user4.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user4)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        delayVault.user4.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
        packedData,
      );
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId);
    expect(data.owner).to.equal(delayVault.user4.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier1.div(2)]);
  });

  it('should create new delay nft after split with first tier', async () => {
    const params = [delayVault.tier1];
    const packedData = ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'address'],
      [delayVault.ratio, delayVault.user3.address],
    );
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
        packedData,
      );
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier1.div(2)]);
  });

  it('should create new delay nft after split with second tier', async () => {
    const params = [delayVault.tier2];
    const packedData = ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'address'],
      [delayVault.ratio, delayVault.user3.address],
    );
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
        packedData,
      );
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier2.div(2)]);
  });

  it('should create new delay nft after split with third tier', async () => {
    const params = [delayVault.tier3];
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    const packedData = ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'address'],
      [delayVault.ratio, delayVault.user3.address],
    );
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
        packedData,
      );
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier3.div(2)]);
  });
});
