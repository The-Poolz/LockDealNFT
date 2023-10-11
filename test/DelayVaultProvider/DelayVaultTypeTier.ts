import { delayVault } from './setupTests';
import { expect } from 'chai';

describe('DelayVaultProvider type tier tests', async () => {
  before(async () => {
    await delayVault.initialize();
  });

  beforeEach(async () => {
    delayVault.poolId = await delayVault.lockDealNFT.totalSupply();
  });

  it('checking default type tier', async () => {
    expect(await delayVault.delayVaultProvider.userToType(delayVault.user1.address)).to.equal(0);
  });

  it('should upgrade type tier', async () => {
    const params = [delayVault.tier1];
    const newType = 2;
    await delayVault.delayVaultProvider.connect(delayVault.user1).createNewDelayVault(delayVault.user1.address, params);
    await delayVault.delayVaultProvider.connect(delayVault.user1).upgradeType(newType);
    expect(await delayVault.delayVaultProvider.userToType(delayVault.user1.address)).to.equal(newType);
  });

  it("should revert if user doesn't have delayVault", async () => {
    await expect(delayVault.delayVaultProvider.connect(delayVault.user2).upgradeType(2)).to.be.revertedWith(
      'amount must be bigger than 0',
    );
  });

  it('should revert if new tier smaller that old one', async () => {
    const params = [delayVault.tier2];
    await delayVault.delayVaultProvider.connect(delayVault.user2).createNewDelayVault(delayVault.user2.address, params);
    await expect(delayVault.delayVaultProvider.connect(delayVault.user2).upgradeType(0)).to.be.revertedWith(
      'new type must be bigger than the old one',
    );
  });

  it('should revert if set new tier bigger than max tier', async () => {
    await expect(delayVault.delayVaultProvider.connect(delayVault.user2).upgradeType(255)).to.be.revertedWith(
      'new type must be smaller than the types count',
    );
  });

  it("upgradeType call after one user created delayVault for another user's address", async () => {
    const params = [delayVault.tier1];
    const newType = 2;
    await delayVault.delayVaultProvider.connect(delayVault.user2).createNewDelayVault(delayVault.user3.address, params);
    await delayVault.delayVaultProvider.connect(delayVault.user3).upgradeType(newType);
    expect(await delayVault.delayVaultProvider.userToType(delayVault.user3.address)).to.equal(newType);
  });

  it('The type level should be increased if the user will have multiple nfts', async () => {
    let params = [delayVault.tier1];
    await delayVault.delayVaultProvider.connect(delayVault.user4).createNewDelayVault(delayVault.user4.address, params);
    params = [delayVault.tier1];
    await delayVault.delayVaultProvider.connect(delayVault.user4).createNewDelayVault(delayVault.user4.address, params);
    expect(await delayVault.delayVaultProvider.userToType(delayVault.user4.address)).to.equal(1);
  });

});
