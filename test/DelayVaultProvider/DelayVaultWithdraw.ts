import { _createUsers, token } from '../helper';
import { delayVault } from './setupTests';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('delayVault withdraw', async () => {
  before(async () => {
    await delayVault.initialize();
  });

  beforeEach(async () => {
    delayVault.poolId = await delayVault.lockDealNFT.totalSupply();
  });

  it('should withdraw from delayVault with tier 1', async () => {
    const params = [delayVault.tier1];
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
      );
    const newAmount = await delayVault.delayVaultProvider.userToAmount(delayVault.user3.address);
    const type = await delayVault.delayVaultProvider.userToType(delayVault.user3.address);
    expect(newAmount).to.equal(0);
    expect(type).to.equal(0);
  });

  it('should withdraw from delayVault with tier 2', async () => {
    const params = [delayVault.tier2];
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
      );
    const newAmount = await delayVault.delayVaultProvider.userToAmount(delayVault.user3.address);
    const type = await delayVault.delayVaultProvider.userToType(delayVault.user3.address);
    expect(newAmount).to.equal(0);
    expect(type).to.equal(0);
  });

  it('should withdraw from delayVault with tier 3', async () => {
    const params = [delayVault.tier3];
    const poolId = await delayVault.lockDealNFT.totalSupply();
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256)'](delayVault.user3.address, delayVault.lockDealNFT.address, poolId);
    const newAmount = await delayVault.delayVaultProvider.userToAmount(delayVault.user3.address);
    const type = await delayVault.delayVaultProvider.userToType(delayVault.user3.address);
    expect(newAmount).to.equal(0);
    expect(type).to.equal(0);
  });

  it('should create new deal provider nft after withdraw with first tier', async () => {
    const params = [delayVault.tier1];
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
      );
    delayVault.vaultId = await delayVault.mockVaultManager.Id();
    const simpleNFTdata = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(simpleNFTdata.provider).to.equal(delayVault.dealProvider.address);
    expect(simpleNFTdata.owner).to.equal(delayVault.user3.address);
    expect(simpleNFTdata.token).to.equal(token);
    expect(simpleNFTdata.vaultId).to.equal(delayVault.vaultId);
    expect(simpleNFTdata.params).to.deep.equal([delayVault.tier1]);
  });

  it('should create new lock provider nft after withdraw with second tier', async () => {
    const params = [delayVault.tier2];
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
      );
    const time = await ethers.provider.getBlock('latest').then(block => block.timestamp);
    delayVault.vaultId = await delayVault.mockVaultManager.Id();
    const simpleNFTdata = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(simpleNFTdata.provider).to.equal(delayVault.lockProvider.address);
    expect(simpleNFTdata.owner).to.equal(delayVault.user3.address);
    expect(simpleNFTdata.token).to.equal(token);
    expect(simpleNFTdata.vaultId).to.equal(delayVault.vaultId);
    expect(simpleNFTdata.params).to.deep.equal([delayVault.tier2, time + delayVault.startTime]);
  });

  it('should create new timed provider nft after withdraw with third tier', async () => {
    const params = [delayVault.tier3];
    await delayVault.delayVaultProvider.connect(delayVault.user3).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.lockDealNFT
      .connect(delayVault.user3)
      ['safeTransferFrom(address,address,uint256)'](
        delayVault.user3.address,
        delayVault.lockDealNFT.address,
        delayVault.poolId,
      );
    const time = await ethers.provider.getBlock('latest').then(block => block.timestamp);
    delayVault.vaultId = await delayVault.mockVaultManager.Id();
    const simpleNFTdata = await delayVault.lockDealNFT.getData(delayVault.poolId.add(1));
    expect(simpleNFTdata.provider).to.equal(delayVault.timedDealProvider.address);
    expect(simpleNFTdata.owner).to.equal(delayVault.user3.address);
    expect(simpleNFTdata.token).to.equal(token);
    expect(simpleNFTdata.vaultId).to.equal(delayVault.vaultId);
    expect(simpleNFTdata.params).to.deep.equal([
      delayVault.tier3,
      time + delayVault.startTime,
      time + delayVault.finishTime,
      delayVault.tier3,
    ]);
  });
});
