import { 
    LockDealProvider,
    MultiWithdrawProvider,
    TimedDealProvider,
    LockDealNFT,
    DealProvider,
    VaultManager,
    ERC20Token
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
    let vaultManager: VaultManager;
    let lockDealNFT: LockDealNFT;
    let dealProvider: DealProvider;
    let lockProvider: LockDealProvider;
    let timedDealProvider: TimedDealProvider;
    let multiWitherProivder: MultiWithdrawProvider;
    let lockDealParams: [number, number];
    const maxPoolsPerTx = 500;
    const amount = 10000;
    const poolsPerToken = 10;
    const tokens: ERC20Token[] = []

    before(async () => {
        [owner, user] = await ethers.getSigners();
        vaultManager = await deployed('VaultManager');
        lockDealNFT = await deployed('LockDealNFT', vaultManager.address, '');
        dealProvider = await deployed('DealProvider', lockDealNFT.address);
        lockProvider = await deployed('LockDealProvider', lockDealNFT.address, dealProvider.address);
        timedDealProvider = await deployed('TimedDealProvider', lockDealNFT.address, lockProvider.address);
        multiWitherProivder = await deployed('MultiWithdrawProvider', lockDealNFT.address, maxPoolsPerTx.toString());
        tokens.push(await deployed('ERC20Token', 'TestTokenA', 'TTA'));
        tokens.push(await deployed('ERC20Token', 'TestTokenA', 'TTA'));
        tokens.push(await deployed('ERC20Token', 'TestTokenA', 'TTA'));
        const approvePromise = tokens.map(async (token) => {
            await token.approve(vaultManager.address, constants.MaxUint256);
        })
        const promises = [
            lockDealNFT.setApprovedProvider(dealProvider.address, true),
            lockDealNFT.setApprovedProvider(lockProvider.address, true),
            lockDealNFT.setApprovedProvider(timedDealProvider.address, true),
            lockDealNFT.setApprovedProvider(multiWitherProivder.address, true),
            vaultManager.setTrustee(lockDealNFT.address),
            vaultManager['createNewVault(address)'](tokens[0].address),
            vaultManager['createNewVault(address)'](tokens[1].address),
            vaultManager['createNewVault(address)'](tokens[2].address),
        ];
        await Promise.all([...promises, ...approvePromise]);
    })

    describe("MultiWithdraw LockDealProvider", () => {
        before(async () => {
            const array = Array.from({ length: poolsPerToken }, (_, index) => index + 1); // array of ten elements
            const startTime = (await time.latest()) + 100;
            // console.log("startTime",startTime)
            lockDealParams = [amount, startTime];
            // poolId = (await lockDealNFT.totalSupply()).toNumber();
            const creation1 = array.map(() => {
                const token = tokens[0];
                const addresses = [user.address, token.address];
                return lockProvider.createNewPool(addresses, lockDealParams);
            });
            const creation2 = array.map(() => {
                const token = tokens[1];
                const addresses = [user.address, token.address];
                return lockProvider.createNewPool(addresses, lockDealParams);
            });
            const creation3 = array.map(() => {
                const token = tokens[2];
                const addresses = [user.address, token.address];
                return lockProvider.createNewPool(addresses, lockDealParams);
            });
            await Promise.all([...creation1, ...creation2, ...creation3]);
        });
    
        it("should have correct withdrawable amount", async () => {
            await mine(100);
            const withdrawablwAmount1 = await multiWitherProivder.getWithdrawableAmountOfToken(user.address, tokens[0].address);
            const withdrawablwAmount2 = await multiWitherProivder.getWithdrawableAmountOfToken(user.address, tokens[1].address);
            const withdrawablwAmount3 = await multiWitherProivder.getWithdrawableAmountOfToken(user.address, tokens[2].address);
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