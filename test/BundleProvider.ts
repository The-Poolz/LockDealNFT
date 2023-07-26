import { LockDealProvider } from "../typechain-types"
import { TimedDealProvider } from "../typechain-types"
import { LockDealNFT } from "../typechain-types"
import { DealProvider } from "../typechain-types"
import { MockVaultManager } from "../typechain-types"
import { MockProvider } from "../typechain-types"
import { BundleProvider } from "../typechain-types"
import { deployed, token } from "./helper"
import { time, mine } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { BigNumber, constants } from "ethers"
import { ethers } from "hardhat"

describe("Lock Deal Bundle Provider", function () {
    let bundleProvider: BundleProvider
    let mockProvider: MockProvider
    let timedDealProvider: TimedDealProvider
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
    let lockDealNFT: LockDealNFT
    let bundlePoolId: number
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let startTime: number, finishTime: number
    let params: [BigNumber[], (number | BigNumber)[], (number | BigNumber)[]]
    const amount = BigNumber.from(100000)
    const ONE_DAY = 86400

    before(async () => {
        [receiver, newOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address, "")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedDealProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
        bundleProvider = await deployed("BundleProvider", lockDealNFT.address)
        mockProvider = await deployed("MockProvider", lockDealNFT.address, bundleProvider.address)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedDealProvider.address, true)
        await lockDealNFT.setApprovedProvider(bundleProvider.address, true)
        await lockDealNFT.setApprovedProvider(mockProvider.address, true)
    })

    beforeEach(async () => {
        startTime = await time.latest() + ONE_DAY   // plus 1 day
        finishTime = startTime + 7 * ONE_DAY   // plus 7 days from `startTime`
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        params = [dealProviderParams, lockProviderParams, timedDealProviderParams]
        bundlePoolId = (await lockDealNFT.totalSupply()).toNumber()
        await bundleProvider.createNewPool(receiver.address, token, bundleProviders, params)
    })

    it("should return provider name", async () => {
        expect(await bundleProvider.name()).to.equal("BundleProvider")
    })

    it("should check lock deal NFT address", async () => {
        const nftAddress = await bundleProvider.lockDealNFT()
        expect(nftAddress.toString()).to.equal(lockDealNFT.address)
    })

    it("should get bundle provider data after creation", async () => {
        const poolData = await lockDealNFT.getData(bundlePoolId);
        const params = [bundlePoolId + 3]
        // check the pool data
        expect(poolData).to.deep.equal([bundleProvider.address, bundlePoolId, receiver.address, token, params])

        // check the NFT ownership
        expect(await lockDealNFT.ownerOf(bundlePoolId)).to.equal(receiver.address);
        expect(await lockDealNFT.ownerOf(bundlePoolId + 1)).to.equal(bundleProvider.address);
        expect(await lockDealNFT.ownerOf(bundlePoolId + 2)).to.equal(bundleProvider.address);
        expect(await lockDealNFT.ownerOf(bundlePoolId + 3)).to.equal(bundleProvider.address);
    })

    it("should check cascade NewPoolCreated event", async () => {
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams, timedDealProviderParams]

        const tx = await bundleProvider.createNewPool(receiver.address, token, bundleProviders, bundleProviderParams)
        await tx.wait()
        const event = await dealProvider.queryFilter(dealProvider.filters.NewPoolCreated())
        const data = event[event.length - 1].args
        const lastPoolId = (await lockDealNFT.totalSupply()).toNumber() - 1;

        expect(data.poolId).to.equal(lastPoolId)
        expect(data.token).to.equal(constants.AddressZero)
        expect(data.owner).to.equal(bundleProvider.address)
        expect(data.params[0]).to.equal(amount)
    })

    it("should revert invalid provider address", async () => {
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams, timedDealProviderParams]

        // zero address
        bundleProviders[0] = constants.AddressZero
        await expect(
            bundleProvider.createNewPool(receiver.address, token, bundleProviders, bundleProviderParams)
        ).to.be.revertedWith("Provider not approved")

        // lockDealNFT address
        bundleProviders[0] = lockDealNFT.address
        await expect(
            bundleProvider.createNewPool(receiver.address, token, bundleProviders, bundleProviderParams)
        ).to.be.revertedWith("invalid provider address")

        // bundleProvider address
        bundleProviders[0] = bundleProvider.address
        await expect(
            bundleProvider.createNewPool(receiver.address, token, bundleProviders, bundleProviderParams)
            ).to.be.revertedWith("invalid provider address")
    })

    it("should revert if the provider count is mismatched with the params count", async () => {
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        // const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams]

        await expect(
            bundleProvider.createNewPool(receiver.address, token, bundleProviders, bundleProviderParams)).to.be.revertedWith(
                "providers and params length mismatch"
            )
    })

    it("should revert if the provider count is not greater than 1", async () => {
        const dealProviderParams = [amount]
        const bundleProviders = [dealProvider.address,]
        const bundleProviderParams = [dealProviderParams]

        await expect(
            bundleProvider.createNewPool(receiver.address, token, bundleProviders, bundleProviderParams)).to.be.revertedWith(
                "providers length must be greater than 1"
            )
    })

    it("should revert zero token address", async () => {
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams, timedDealProviderParams]

        await expect(bundleProvider.createNewPool(receiver.address, constants.AddressZero, bundleProviders, bundleProviderParams)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert if the poolId is not the bundle poolId", async () => {
        await expect(bundleProvider.getTotalRemainingAmount(bundlePoolId - 1)).to.be.revertedWith("not bundle poolId");
    })

    describe("Lock Deal Bundle Withdraw", () => {
        it("should withdraw all dealProvider tokens before the startTime", async () => {
            await time.setNextBlockTimestamp(startTime - 1)
            const beforeRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId) 
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, bundlePoolId)
            const afterRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId) 
            expect(beforeRemainingAmount).to.equal(amount.mul(3))
            expect(afterRemainingAmount).to.equal(amount.mul(2))
        })

        it("should withdraw all dealProvider/lockProvider tokens from bundle at the startTime", async () => {
            await time.setNextBlockTimestamp(startTime)
            const beforeRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, bundlePoolId)
            const afterRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId) 
            expect(beforeRemainingAmount).to.equal(amount.mul(3))
            expect(afterRemainingAmount).to.equal(amount)
        })

        it("should withdraw dealProvider, lockProvider and half timedProvider tokens", async () => {
            const halfTime = (finishTime - startTime) / 2
            await time.setNextBlockTimestamp(startTime + halfTime)
            const beforeRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, bundlePoolId)
            const afterRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId) 
            expect(beforeRemainingAmount).to.equal(amount.mul(3))
            expect(afterRemainingAmount).to.equal(amount.div(2))
        })

        it("should withdraw all tokens after the finishTime", async () => {
            await time.setNextBlockTimestamp(finishTime)
            const beforeRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, bundlePoolId)
            const afterRemainingAmount = await bundleProvider.getTotalRemainingAmount(bundlePoolId) 
            expect(beforeRemainingAmount).to.equal(amount.mul(3))
            expect(afterRemainingAmount).to.equal(0)
        })

        it("should get only dealProvider amount", async () => {
            const withdrawAmount = await lockDealNFT.getWithdrawableAmount(bundlePoolId)
            expect(withdrawAmount).to.equal(amount)
        })

        it("should get dealProvider and lockProvider amount", async () => {
            await time.setNextBlockTimestamp(startTime)
            await mine(1)
            const withdrawAmount = await lockDealNFT.getWithdrawableAmount(bundlePoolId)
            expect(withdrawAmount).to.equal(amount.mul(2))
        })

        it("should get full amount", async () => {
            await time.setNextBlockTimestamp(finishTime)
            await mine(1)
            const withdrawAmount = await lockDealNFT.getWithdrawableAmount(bundlePoolId)
            expect(withdrawAmount).to.equal(amount.mul(3))
        })

        it("should revert if not called from the lockDealNFT contract", async () => {
            await expect(bundleProvider.withdraw(constants.AddressZero, constants.AddressZero, 10, [])).to.be.revertedWith("only NFT contract can call this function")
        })
    })

    describe("Lock Deal Bundle Split Amount", () => {
        it("should check the pool data after split", async () => {
            const newPoolId = (await lockDealNFT.totalSupply()).toNumber();
            const splitAmount = amount.mul(3).div(10);  // totalAmount = amount*3, splitAmount = amount*3/10, rate = 10
            await lockDealNFT.split(bundlePoolId, splitAmount, newOwner.address)
            const params = [bundlePoolId + 3]
            const oldPoolData = await lockDealNFT.getData(bundlePoolId);
            const newPoolData = await lockDealNFT.getData(newPoolId);

            // check the old bundle pool data
            expect(oldPoolData).to.deep.equal([bundleProvider.address, bundlePoolId, receiver.address, token, params])

            expect(await lockDealNFT.ownerOf(bundlePoolId)).to.equal(receiver.address); // old bundle pool
            expect(await lockDealNFT.ownerOf(bundlePoolId + 1)).to.equal(bundleProvider.address); // first sub pool
            expect(await lockDealNFT.ownerOf(bundlePoolId + 2)).to.equal(bundleProvider.address); // second sub pool
            expect(await lockDealNFT.ownerOf(bundlePoolId + 3)).to.equal(bundleProvider.address); // third sub pool

            expect((await lockDealNFT.getData(bundlePoolId + 1)).params[0]).to.equal(amount.mul(9).div(10));  // first sub pool
            expect((await lockDealNFT.getData(bundlePoolId + 2)).params[0]).to.equal(amount.mul(9).div(10));  // second sub pool
            expect((await lockDealNFT.getData(bundlePoolId + 3)).params[0]).to.equal(amount.mul(9).div(10));  // third sub pool

            // check the new bundle pool data
            expect(newPoolData).to.deep.equal([bundleProvider.address, newPoolId, newOwner.address, token, [newPoolId + 3]])

            expect(await lockDealNFT.ownerOf(newPoolId)).to.equal(newOwner.address);    // new bundle pool
            expect(await lockDealNFT.ownerOf(newPoolId + 1)).to.equal(bundleProvider.address);  // first sub pool
            expect(await lockDealNFT.ownerOf(newPoolId + 2)).to.equal(bundleProvider.address);  // second sub pool
            expect(await lockDealNFT.ownerOf(newPoolId + 3)).to.equal(bundleProvider.address);  // third sub pool

            expect((await lockDealNFT.getData(newPoolId + 1)).params[0]).to.equal(amount.div(10));  // first sub pool
            expect((await lockDealNFT.getData(newPoolId + 2)).params[0]).to.equal(amount.div(10));  // second sub pool
            expect((await lockDealNFT.getData(newPoolId + 3)).params[0]).to.equal(amount.div(10));  // third sub pool
        })

        it("should revert if the split amount is invalid", async () => {
            const splitAmount = amount.mul(3);  // totalAmount = amount*3, splitAmount = amount*3, rate = 1
            await expect(lockDealNFT.split(bundlePoolId, splitAmount, newOwner.address)).to.be.revertedWith("split amount exceeded")  
        })

        it("should revert if not called from the lockDealNFT contract", async () => {
            const splitAmount = amount.mul(3).div(10);  // totalAmount = amount*3, splitAmount = amount*3/10, rate = 10
            await expect(bundleProvider.split(bundlePoolId, splitAmount, newOwner.address)).to.be.revertedWith("invalid provider address")  
        })
    })

    describe("Mock register pool tests", () => {
        let params: [number]

        beforeEach(async () => {
            const lastSubPoolId = (await lockDealNFT.totalSupply()).toNumber() - 1

            params = [lastSubPoolId]
        })

        it("should register pool", async () => {
            await mockProvider.registerPool(bundlePoolId, params)

            const poolData = await lockDealNFT.getData(bundlePoolId)
            expect(poolData).to.deep.equal([bundleProvider.address, bundlePoolId, receiver.address, token, params])
        })

        it("should revert invalid last sub pool id", async () => {
            params[0] = bundlePoolId - 1
            await expect(mockProvider.registerPool(bundlePoolId, params)).to.be.revertedWith("poolId can't be greater than lastSubPoolId")
        })

        it("should revert invalid pool owner", async () => {
            await dealProvider.createNewPool(receiver.address, token, params)
            params[0] = (await lockDealNFT.totalSupply()).toNumber() - 1
            await expect(mockProvider.registerPool(bundlePoolId, params)).to.be.revertedWith("invalid owner of sub pool")
        })
    })
})
