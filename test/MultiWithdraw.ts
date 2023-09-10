import { 
    LockDealProvider,
    MultiWithdrawProvider,
    TimedDealProvider,
    LockDealNFT,
    DealProvider,
    MockVaultManager
} from '../typechain-types';
import { deployed, BUSD, MAX_RATIO, token } from './helper';
import { mine, time } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

describe("MultiWithdraw", () => {
    let owner: SignerWithAddress;
    let user: SignerWithAddress;
    let mockVaultManager: MockVaultManager;
    let lockDealNFT: LockDealNFT;
    let dealProvider: DealProvider;
    let lockProvider: LockDealProvider;
    let timedDealProvider: TimedDealProvider;
    let multiWitherProivder: MultiWithdrawProvider;
    let lockDealParams: [number, number];
    const maxPoolsPerTx = 500;
    const amount = 10000;
    const poolsPerToken = 10;
    const tokens = [
        "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
        "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82",
        "0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3",
    ]

    before(async () => {
        [owner, user] = await ethers.getSigners();
        mockVaultManager = await deployed('MockVaultManager');
        lockDealNFT = await deployed('LockDealNFT', mockVaultManager.address, '');
        dealProvider = await deployed('DealProvider', lockDealNFT.address);
        lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
        timedDealProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
        multiWitherProivder = await deployed('MultiWithdrawProvider', lockDealNFT.address, maxPoolsPerTx.toString());
        await lockDealNFT.setApprovedProvider(dealProvider.address, true);
        await lockDealNFT.setApprovedProvider(lockProvider.address, true);
        await lockDealNFT.setApprovedProvider(timedDealProvider.address, true);
        await lockDealNFT.setApprovedProvider(multiWitherProivder.address, true);
    })

    describe("MultiWithdraw LockDealProvider", () => {
        before(async () => {
            const array = Array.from({ length: poolsPerToken }, (_, index) => index + 1); // array of ten elements
            const startTime = (await time.latest()) + 100;
            console.log("startTime",startTime)
            lockDealParams = [amount, startTime];
            // poolId = (await lockDealNFT.totalSupply()).toNumber();
            const creation1 = array.map(() => {
                const token = tokens[0];
                const addresses = [user.address, token];
                return lockProvider.createNewPool(addresses, lockDealParams);
            });
            const creation2 = array.map(() => {
                const token = tokens[1];
                const addresses = [user.address, token];
                return lockProvider.createNewPool(addresses, lockDealParams);
            });
            const creation3 = array.map(() => {
                const token = tokens[2];
                const addresses = [user.address, token];
                return lockProvider.createNewPool(addresses, lockDealParams);
            });
            const allCreations = await Promise.all([...creation1, ...creation2, ...creation3]);
            // console.log(allCreations)
            const vaultId = await mockVaultManager.Id();
            console.log(vaultId)
        });
    
        it("should have correct withdrawable amount", async () => {
            await mine(100);
            const withdrawablwAmount1 = await multiWitherProivder.getWithdrawableAmountOfToken(user.address, tokens[0]);
            const withdrawablwAmount2 = await multiWitherProivder.getWithdrawableAmountOfToken(user.address, tokens[1]);
            const withdrawablwAmount3 = await multiWitherProivder.getWithdrawableAmountOfToken(user.address, tokens[2]);
            expect(withdrawablwAmount1).to.equal(amount * poolsPerToken);
            expect(withdrawablwAmount2).to.equal(amount * poolsPerToken);
            expect(withdrawablwAmount3).to.equal(amount * poolsPerToken);
        })

        it("should fail to multiwithdraw when not approved by user", async () => {
            await expect(multiWitherProivder.multiWithdrawAllPoolsOfOwner(user.address)).to.be.revertedWith("ERC721: transfer caller is not owner nor approved");
        })

        it("should multiwithdraw", async () => {
            await lockDealNFT.connect(user).setApprovalForAll(multiWitherProivder.address, true);
            const tx = await multiWitherProivder.multiWithdrawAllPoolsOfOwner(user.address);
            const receipt = await tx.wait();
            console.log(receipt)
        })
    })


});