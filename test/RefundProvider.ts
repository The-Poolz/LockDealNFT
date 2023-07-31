import { MockVaultManager } from "../typechain-types"
import { DealProvider } from "../typechain-types"
import { LockDealNFT } from "../typechain-types"
import { LockDealProvider } from "../typechain-types"
import { RefundProvider } from "../typechain-types"
import { TimedDealProvider } from "../typechain-types"
import { CollateralProvider } from "../typechain-types"
import { MockProvider } from "../typechain-types"
import { deployed, token, BUSD } from "./helper"
import { time, mine } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { BigNumber, constants } from "ethers"
import { ethers } from "hardhat"

describe("Refund Provider", function () {
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
    let mockProvider: MockProvider
    let refundProvider: RefundProvider
    let timedProvider: TimedDealProvider
    let collateralProvider: CollateralProvider
    let halfTime: number
    const rate = ethers.utils.parseEther("0.1")
    const mainCoinAmount = ethers.utils.parseEther("10")
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let projectOwner: SignerWithAddress
    let params: [BigNumber, number, number, BigNumber, BigNumber, number]
    let startTime: number, finishTime: number
    const amount = ethers.utils.parseEther("100")
    const ONE_DAY = 86400

    before(async () => {
        [receiver, projectOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address, "")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
        collateralProvider = await deployed("CollateralProvider", lockDealNFT.address, dealProvider.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, collateralProvider.address)
        mockProvider = await deployed("MockProvider", lockDealNFT.address, refundProvider.address)
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedProvider.address, true)
        await lockDealNFT.setApprovedProvider(collateralProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockDealNFT.address, true)
        await lockDealNFT.setApprovedProvider(mockProvider.address, true)
    })

    beforeEach(async () => {
        startTime = (await time.latest()) + ONE_DAY // plus 1 day
        finishTime = startTime + 7 * ONE_DAY // plus 7 days from `startTime`
        params = [amount, startTime, finishTime, mainCoinAmount, rate, finishTime]
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await refundProvider
            .connect(projectOwner)
            .createNewRefundPool(token, receiver.address, BUSD, timedProvider.address, params)
        halfTime = (finishTime - startTime) / 2
    })

    it("should return provider name", async () => {
        expect(await refundProvider.name()).to.equal("RefundProvider")
    })


    describe("Pool Creation", async () => {
        it("should return refund pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId)
            const params = [poolId + 2, rate]
            expect(poolData).to.deep.equal([refundProvider.address, poolId, receiver.address, constants.AddressZero, params])
        })

        it("should return currect token pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 1)
            const params = [amount, startTime, finishTime, amount]
            expect(poolData).to.deep.equal([timedProvider.address, poolId + 1, refundProvider.address, token, params])
        })

        it("should return currect collateral pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 2)
            const params = [mainCoinAmount, finishTime]
            expect(poolData).to.deep.equal([collateralProvider.address, poolId + 2, projectOwner.address, BUSD, params])
        })

        it("should return currect main coin collector pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 3)
            const params = [0]
            expect(poolData).to.deep.equal([dealProvider.address, poolId + 3, collateralProvider.address, BUSD, params])
        })

        it("should return currect token collector pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 4)
            const params = [0]
            expect(poolData).to.deep.equal([dealProvider.address, poolId + 4, collateralProvider.address, token, params])
        })

        it("should return currect main coin holder pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 5)
            const params = [mainCoinAmount]
            expect(poolData).to.deep.equal([dealProvider.address, poolId + 5, collateralProvider.address, BUSD, params])
        })

        it("should return metada register after creation", async () => {
            const tx = await mockProvider.registerPool(poolId, params)
            await tx.wait()
            const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MetadataUpdate())
            expect(events[events.length - 1].args._tokenId).to.equal(poolId)
        })
    })

    describe("Split Pool", async () => {
        it("should return currect pool data after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)
            const params = [poolId + 2, rate]
            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData).to.deep.equal([refundProvider.address, poolId, receiver.address, constants.AddressZero, params])
        })

        it("should return new pool data after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)
            const params = [poolId + 2, rate]
            const poolData = await lockDealNFT.getData(poolId + 6)
            expect(poolData).to.deep.equal([refundProvider.address, poolId + 6, receiver.address, constants.AddressZero, params])
        })

        it("should return old data for user after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)
            const params = [amount.div(2), startTime, finishTime, amount.div(2)]
            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData).to.deep.equal([timedProvider.address, poolId + 1, refundProvider.address, token, params])
        })

        it("should return new data for user after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)
            const params = [amount.div(2), startTime, finishTime, amount.div(2)]
            const poolData = await lockDealNFT.getData(poolId + 7)
            expect(poolData).to.deep.equal([timedProvider.address, poolId + 7, refundProvider.address, token, params])
        })
    })

    describe("Withdraw Pool", async () => {
        it("should withdraw tokens from pool after time", async () => {
            await time.setNextBlockTimestamp(finishTime + 1)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)
            const poolData = await lockDealNFT.getData(poolId + 1)
            const params = [0, startTime, finishTime, amount]
            expect(poolData).to.deep.equal([timedProvider.address, poolId + 1, refundProvider.address, token, params])
        })

        it("should withdraw half tokens from pool after halfTime", async () => {
            await time.setNextBlockTimestamp(startTime + halfTime)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)
            const params = [amount.div(2), startTime, finishTime, amount]
            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData).to.deep.equal([timedProvider.address, poolId + 1, refundProvider.address, token, params])
        })

        it("should increase token collector pool after halfTime", async () => {
            await time.setNextBlockTimestamp(startTime + halfTime)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)
            const params = [mainCoinAmount.div(2)]
            const poolData = await lockDealNFT.getData(poolId + 3)
            expect(poolData).to.deep.equal([dealProvider.address, poolId + 3, collateralProvider.address, BUSD, params])
        })

        it("should get zero tokens from pool before time", async () => {
            const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId)
            expect(withdrawAmount).to.equal(0)
        })

        it("should get full amount after time", async () => {
            await time.setNextBlockTimestamp(finishTime)
            await mine(1)
            const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId)
            expect(withdrawAmount).to.equal(amount)
        })

        it("should get half amount", async () => {
            await time.setNextBlockTimestamp(startTime + halfTime)
            await mine(1)
            const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId)
            expect(withdrawAmount).to.equal(amount.div(2))
        })
    })

    describe("Refund Pool", async () => {
        it("the user receives the main coins", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId)
            const newMainCoinPoolId = (await lockDealNFT.totalSupply()).toNumber() - 1
            const poolData = await lockDealNFT.getData(newMainCoinPoolId)
            expect(poolData).to.deep.equal([dealProvider.address, newMainCoinPoolId, receiver.address, BUSD, [mainCoinAmount]])
        })

        it("the project owner receives the tokens", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId)
            const poolData = await lockDealNFT.getData(poolId + 4)
            expect(poolData).to.deep.equal([dealProvider.address, poolId + 4, collateralProvider.address, token, [amount]])
        })
      })
})