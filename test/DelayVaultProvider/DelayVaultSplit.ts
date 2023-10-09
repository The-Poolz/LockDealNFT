import { _createUsers } from '../helper';
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

  async function split(user: SignerWithAddress, params: BigNumber[]) {
    const bytes = ethers.utils.defaultAbiCoder.encode(['uint256', 'address'], [delayVault.ratio, user.address]);
    await delayVault.delayVaultProvider.connect(user).createNewDelayVault(user.address, params);
    await delayVault.lockDealNFT
      .connect(user)
      ['safeTransferFrom(address,address,uint256,bytes)'](
        user.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
        bytes,
      );
  }

  it('should return half amount in old pool after split', async () => {
    await split(delayVault.user4, [delayVault.tier1]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId);
    expect(data.owner).to.equal(delayVault.user4.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier1.div(2)]);
  });

  it('should create new delay nft after split with first tier', async () => {
    await split(delayVault.user3, [delayVault.tier1]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier1.div(2)]);
  });

  it('should create new delay nft after split with second tier', async () => {
    await split(delayVault.user3, [delayVault.tier2]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier2.div(2)]);
  });

  it('should create new delay nft after split with third tier', async () => {
    await split(delayVault.user3, [delayVault.tier3]);
    const data = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(data.owner).to.equal(delayVault.user3.address);
    expect(data.provider).to.equal(delayVault.delayVaultProvider.address);
    expect(data.params).to.deep.equal([delayVault.tier3.div(2)]);
  });
});
