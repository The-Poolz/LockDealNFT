import { token, _createUsers } from '../helper';
import { delayVault } from './setupTests';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('DelayVault Provider', function () {
  before(async () => {
    await delayVault.initialize();
  });

  beforeEach(async () => {
    delayVault.poolId = await delayVault.lockDealNFT.totalSupply();
  });

  it('should check provider name', async () => {
    expect(await delayVault.delayVaultProvider.name()).to.equal('DelayVaultProvider');
  });

  it("should check provider's token", async () => {
    expect(await delayVault.delayVaultProvider.token()).to.equal(token);
  });

  it("should check provider's lockDealNFT", async () => {
    expect(await delayVault.delayVaultProvider.lockDealNFT()).to.equal(delayVault.lockDealNFT.address);
  });

  it('should check _finilize constructor data', async () => {
    for (let i = 0; i < delayVault.providerData.length; i++) {
      const data = await delayVault.delayVaultProvider.getTypeToProviderData(i);
      expect(data.provider).to.equal(delayVault.providerData[i].provider);
      expect(data.params).to.deep.equal(delayVault.providerData[i].params);
      i != delayVault.providerData.length - 1
        ? expect(data.limit).to.equal(delayVault.providerData[i].limit)
        : expect(data.limit).to.equal(ethers.constants.MaxUint256);
    }
  });

  it('should return new provider poolId', async () => {
    const params = [delayVault.tier1];
    const lastPoolId = (await delayVault.lockDealNFT.totalSupply()).sub(1);
    await delayVault.delayVaultProvider.createNewDelayVault(delayVault.receiver.address, params);
    expect((await delayVault.lockDealNFT.totalSupply()).sub(1)).to.equal(lastPoolId.add(1));
  });

  it('should check vault data with tier 1', async () => {
    const params = [delayVault.tier1];
    await delayVault.delayVaultProvider.connect(delayVault.user2).createNewDelayVault(delayVault.user1.address, params);
    const newAmount = await delayVault.delayVaultProvider.userToAmount(delayVault.user1.address);
    const type = await delayVault.delayVaultProvider.userToType(delayVault.user1.address);
    expect(newAmount).to.equal(delayVault.tier1);
    // 0 - tier1
    // 1 - tier2
    // 2 - tier3
    expect(type).to.equal(0);
  });

  it('should check delayVault data with tier 2', async () => {
    const params = [delayVault.tier2];
    await delayVault.delayVaultProvider.connect(delayVault.user2).createNewDelayVault(delayVault.user2.address, params);
    const newAmount = await delayVault.delayVaultProvider.userToAmount(delayVault.user2.address);
    const type = await delayVault.delayVaultProvider.userToType(delayVault.user2.address);
    expect(newAmount).to.equal(delayVault.tier2);
    expect(type).to.equal(1);
  });

  it('should check delayVault data with tier 3', async () => {
    const params = [delayVault.tier3];
    await delayVault.delayVaultProvider
      .connect(delayVault.newOwner)
      .createNewDelayVault(delayVault.newOwner.address, params);
    const newAmount = await delayVault.delayVaultProvider.userToAmount(delayVault.newOwner.address);
    const type = await delayVault.delayVaultProvider.userToType(delayVault.newOwner.address);
    expect(newAmount).to.equal(delayVault.tier3);
    expect(type).to.equal(2);
  });
});
