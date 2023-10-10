import { delayVault } from './setupTests';
import { expect } from 'chai';

describe('DelayVaultProvider view tests', async () => {
  before(async () => {
    await delayVault.initialize();
  });

  beforeEach(async () => {
    delayVault.poolId = await delayVault.lockDealNFT.totalSupply();
  });

  it('should return getWithdrawableAmount from created pool', async () => {
    const params = [delayVault.tier2];
    const owner = delayVault.newOwner;
    await delayVault.delayVaultProvider.connect(owner).createNewDelayVault(owner.address, params);
    expect(await delayVault.delayVaultProvider.getWithdrawableAmount(delayVault.poolId)).to.be.equal(delayVault.tier2);
  });

  it('should return type of tier', async () => {
    expect(await delayVault.delayVaultProvider.theTypeOf(delayVault.tier1)).to.be.equal(0);
    expect(await delayVault.delayVaultProvider.theTypeOf(delayVault.tier2)).to.be.equal(1);
    expect(await delayVault.delayVaultProvider.theTypeOf(delayVault.tier3)).to.be.equal(2);
  });

  it('should return total user amount', async () => {
    const params = [delayVault.tier2];
    const owner = delayVault.user1;
    await delayVault.delayVaultProvider.connect(owner).createNewDelayVault(owner.address, params);
    await delayVault.delayVaultProvider.connect(owner).createNewDelayVault(owner.address, params);
    expect(await delayVault.delayVaultProvider.getTotalAmount(owner.address)).to.be.equal(delayVault.tier2.mul(2));
  });
});
