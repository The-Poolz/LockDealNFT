import { MockVaultManager } from "../typechain-types"
import { DealProvider } from "../typechain-types"
import { LockDealNFT } from "../typechain-types"
import { LockDealProvider } from "../typechain-types"
import { RefundProvider } from "../typechain-types"
import { TimedDealProvider } from "../typechain-types"
import { CollateralProvider } from "../typechain-types"
import { deployed, token } from "./helper"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { BigNumber, constants } from "ethers"
import { ethers } from "hardhat"

describe("Refund Provider", function () {
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
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
    let BUSD: string
    let params: [BigNumber, number, number, BigNumber, BigNumber, number]
    let startTime: number, finishTime: number
    const amount = ethers.utils.parseEther("100")
    const ONE_DAY = 86400

    before(async () => {
        [receiver, projectOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
        collateralProvider = await deployed("CollateralProvider", lockDealNFT.address, dealProvider.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, collateralProvider.address)
        BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedProvider.address, true)
        await lockDealNFT.setApprovedProvider(collateralProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockDealNFT.address, true)
    })

    beforeEach(async () => {
        startTime = (await time.latest()) + ONE_DAY // plus 1 day
        finishTime = startTime + 7 * ONE_DAY // plus 7 days from `startTime`
        params = [amount, startTime, finishTime, mainCoinAmount, rate, finishTime]
        poolId = (await lockDealNFT.tokenIdCounter()).toNumber()
        await refundProvider
            .connect(projectOwner)
            .createNewRefundPool(token, receiver.address, BUSD, timedProvider.address, params)
        halfTime = (finishTime - startTime) / 2
    })

    describe("Pool Creation", async () => {
        it("should return refund pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, constants.AddressZero])
            expect(poolData.provider).to.equal(refundProvider.address)
            expect(poolData.params[0]).to.equal(poolId + 2)
            expect(poolData.params[1]).to.equal(rate)
        })

        it("should return currect token pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.provider).to.equal(timedProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount)
            expect(poolData.params[1]).to.equal(startTime)
            expect(poolData.params[2]).to.equal(finishTime)
            expect(poolData.params[3]).to.equal(amount)
        })

        it("should return currect collateral pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 2)
            expect(poolData.provider).to.equal(collateralProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 2, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(mainCoinAmount)
            expect(poolData.params[1]).to.equal(finishTime)
        })

        it("should return currect main coin collector pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 3)
            expect(poolData.provider).to.equal(dealProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 3, collateralProvider.address, BUSD])
            expect(poolData.params[0]).to.equal(0)
        })

        it("should return currect token collector pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 4)
            expect(poolData.provider).to.equal(dealProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 4, collateralProvider.address, token])
            expect(poolData.params[0]).to.equal(0)
        })

        it("should return currect main coin holder pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 5)
            expect(poolData.provider).to.equal(dealProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 5, collateralProvider.address, BUSD])
            expect(poolData.params[0]).to.equal(mainCoinAmount)
        })
    })

    describe("Split Pool", async () => {
        it("should return currect pool data after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)

            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, constants.AddressZero])
            expect(poolData.provider).to.equal(refundProvider.address)
            expect(poolData.params[0]).to.equal(poolId + 2)
            expect(poolData.params[1]).to.equal(rate)
        })

        it("should return new pool data after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 6)
            expect(poolData.poolInfo).to.deep.equal([poolId + 6, receiver.address, constants.AddressZero])
            expect(poolData.params[0]).to.equal(poolId + 2)
            expect(poolData.params[1]).to.equal(rate)
        })

        it("should return old data for user after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount.div(2))
            expect(poolData.params[1]).to.equal(startTime)
            expect(poolData.params[2]).to.equal(finishTime)
            expect(poolData.params[3]).to.equal(amount.div(2))
        })

        it("should return new data for user after split", async () => {
            await lockDealNFT.split(poolId, amount.div(2), receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 7)
            expect(poolData.poolInfo).to.deep.equal([poolId + 7, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount.div(2))
            expect(poolData.params[1]).to.equal(startTime)
            expect(poolData.params[2]).to.equal(finishTime)
            expect(poolData.params[3]).to.equal(amount.div(2))
        })
    })

    describe("Withdraw Pool", async () => {
        it("should withdraw tokens from pool after time", async () => {
            await time.setNextBlockTimestamp(finishTime + 1)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)
            const poolData = await lockDealNFT.getData(poolId + 1)

            expect(poolData.poolInfo).to.deep.equal([poolId + 1, refundProvider.address, token])
            expect(poolData.params[0].toString()).to.equal("0")
        })

        it("should withdraw half tokens from pool after halfTime", async () => {
            await time.setNextBlockTimestamp(startTime + halfTime)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)

            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount.div(2))
            expect(poolData.params[1]).to.equal(startTime)
            expect(poolData.params[2]).to.equal(finishTime)
            expect(poolData.params[3]).to.equal(amount)
        })

        it("should increase token collector pool after halfTime", async () => {
            await time.setNextBlockTimestamp(startTime + halfTime)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, lockDealNFT.address, poolId)

            const poolData = await lockDealNFT.getData(poolId + 3)
            expect(poolData.provider).to.equal(dealProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 3, collateralProvider.address, BUSD])
            expect(poolData.params[0]).to.equal(mainCoinAmount.div(2))
        })
    })

    describe("Refund Pool", async () => {
        it("the user receives the main coins", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId)
            const newMainCoinPoolId = (await lockDealNFT.tokenIdCounter()).toNumber() - 1
            
            const poolData = await lockDealNFT.getData(newMainCoinPoolId)
            expect(poolData.poolInfo).to.deep.equal([newMainCoinPoolId, receiver.address, BUSD])
            expect(poolData.params[0]).to.equal(mainCoinAmount)
        })

        it("the project owner receives the tokens", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId)

            const poolData = await lockDealNFT.getData(poolId + 4)
            expect(poolData.provider).to.equal(dealProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 4, collateralProvider.address, token])
            expect(poolData.params[0]).to.equal(amount)
        })
      })
})