import { expect } from "chai";
import { constants } from "ethers";
import { ethers } from 'hardhat';
import { LockDealNFT } from "../typechain-types";
import { DealProvider } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockVaultManager } from "../typechain-types";
import { deployed, token } from "./helper";

describe("Deal Provider", function () {
    let dealProvider: DealProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let params: [number]
    const amount = 10000

    before(async () => {
        [receiver, newOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address, "")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        params = [amount]
        await dealProvider.createNewPool(receiver.address, token, params)
    })

    it("should return provider name", async () => {
        expect(await dealProvider.name()).to.equal("DealProvider")
    })

    it("should get pool data", async () => {
        const poolData = await lockDealNFT.getData(poolId);
        const params = [amount]
        expect(poolData).to.deep.equal([dealProvider.address, poolId, receiver.address, token, params]);
    })

    it("should check pool creation events", async () => {
        const tx = await dealProvider.createNewPool(receiver.address, token, params)
        await tx.wait()
        const events = await dealProvider.queryFilter(dealProvider.filters.NewPoolCreated())
        expect(events[events.length - 1].args.poolId).to.equal(poolId + 1)
        expect(events[events.length - 1].args.token).to.equal(token)
        expect(events[events.length - 1].args.owner).to.equal(receiver.address)
        expect(events[events.length - 1].args.params[0]).to.equal(amount) //assuming amount is at index 0 in the params array
    })

    it("should check pool creation metadata event", async () => {
        const tx = await dealProvider.createNewPool(receiver.address, token, params)
        await tx.wait()
        const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MetadataUpdate())
        expect(events[events.length - 1].args._tokenId).to.equal(poolId + 1)
    })

    it("should revert zero owner address", async () => {
        await expect(dealProvider.createNewPool(receiver.address, constants.AddressZero, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero token address", async () => {
        await expect(dealProvider.createNewPool(constants.AddressZero, token, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero params", async () => {
        await expect(dealProvider.createNewPool(receiver.address, token, [])).to.be.revertedWith(
            "invalid params length"
        )
    })

    describe("Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            const params = [amount / 2]
            const poolData = await lockDealNFT.getData(poolId);
            expect(poolData).to.deep.equal([dealProvider.address, poolId, receiver.address, token, params]);
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            const params = [amount / 2]
            const poolData = await lockDealNFT.getData(poolId + 1);
            expect(poolData).to.deep.equal([dealProvider.address, poolId + 1, newOwner.address, token, params]);
        })

        it("should return split metadata event", async () => {
            const tx = await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            await tx.wait()
            const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MetadataUpdate())
            expect(events[events.length - 2].args._tokenId).to.equal(poolId)
            expect(events[events.length - 1].args._tokenId).to.equal(poolId + 1)
        })
    })

    describe("Deal Withdraw", () => {
        it("should check data in pool after withdraw", async () => {
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)
            const params = [0]
            const poolData = await lockDealNFT.getData(poolId);
            expect(poolData).to.deep.equal([dealProvider.address, poolId, lockDealNFT.address, token, params]);
        })

        it("should check events after withdraw", async () => {
            poolId = (await lockDealNFT.totalSupply()).toNumber() - 1

            const tx = await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)
            await tx.wait()
            const events = await dealProvider.queryFilter(dealProvider.filters.TokenWithdrawn())
            expect(events[events.length - 1].args.poolId.toString()).to.equal(poolId.toString())
            expect(events[events.length - 1].args.owner.toString()).to.equal(lockDealNFT.address.toString())
            expect(events[events.length - 1].args.withdrawnAmount.toString()).to.equal(amount.toString())
            expect(events[events.length - 1].args.leftAmount.toString()).to.equal("0".toString())
        })

        it("getWithdrawableAmount should get all amount", async () => {
            const withdrawableAmount = await dealProvider.getWithdrawableAmount(poolId)
            expect(withdrawableAmount).to.equal(amount)
        })

        it("should return withdraw metadata event", async () => {
            const tx = await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)
            await tx.wait()
            const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MetadataUpdate())
            expect(events[events.length - 1].args._tokenId).to.equal(poolId)
        })
    })
})
