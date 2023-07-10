import { MockVaultManager } from "../typechain-types"
import { DealProvider } from "../typechain-types/contracts/DealProvider"
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT"
import { LockDealProvider } from "../typechain-types/contracts/LockProvider"
import { TimedDealProvider } from "../typechain-types/contracts/TimedDealProvider";
import { RefundProvider } from "../typechain-types/contracts/RefundProvider"
import { deployed, token } from "./helper"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { constants } from "ethers";
import { ethers } from 'hardhat';

describe("Refund Provider", function () {
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
    let refundProvider: RefundProvider
    let timedProvider: TimedDealProvider
    let halfTime: number
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let projectOwner: SignerWithAddress
    let BUSD: string
    let params: [number, number, number, number, number, number]
    let startTime: number, finishTime: number
    const amount = 10000
    const ONE_DAY = 86400

    before(async () => {
        [receiver, projectOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, lockProvider.address)
        BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedProvider.address, true)
        await lockDealNFT.connect(projectOwner).setApprovalForAll(refundProvider.address, true)
    })

    //  /________________________________,-```-,
    //  | poolId = refundProvider        |     |
    //  | (poolId - 1) = LockDealProvider|     |
    //  | (poolId - 2) = data holder     |     |
    //  \_______________________________/_____/
    beforeEach(async () => {
        startTime = await time.latest() + ONE_DAY   // plus 1 day
        finishTime = startTime + 7 * ONE_DAY   // plus 7 days from `startTime`
        params = [amount, startTime, finishTime, amount, amount / 2, finishTime]
        poolId = (await lockDealNFT.tokenIdCounter()).toNumber()
        await refundProvider
            .connect(projectOwner)
            .createNewRefundPool(token, receiver.address, BUSD, timedProvider.address, params)
        halfTime = (finishTime - startTime) / 2
        })

    describe("Pool Creation", async () => {
        it("should return currect pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect main coin data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.provider).to.equal(lockProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, refundProvider.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(finishTime)
        })

        it("should return currect data for user after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 2)
            expect(poolData.poolInfo).to.deep.equal([poolId + 2, receiver.address, constants.AddressZero])
            expect(poolData.params.toString()).to.equal("")
        })
    })

    describe("Split Pool", async () => {
        it("should return currect pool data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect pool main coin data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, refundProvider.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 4)
            expect(poolData.params[1]).to.equal(finishTime)
        })

        it("should return currect data for user after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 2)
            expect(poolData.poolInfo).to.deep.equal([poolId + 2, receiver.address, constants.AddressZero])
            expect(poolData.params.toString()).to.equal("")
        })

        xit("should return new pool data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 3)
            expect(poolData.poolInfo).to.deep.equal([poolId + 3, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return new pool main coin data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 4)
            expect(poolData.poolInfo).to.deep.equal([poolId + 4, refundProvider.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 4)
            expect(poolData.params[1]).to.equal(finishTime)
        })

        xit("should return new data for user after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 5)
            expect(poolData.poolInfo).to.deep.equal([poolId + 5, receiver.address, token])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })
    })

    describe("Withdraw Pool", async () => {
        it("should withdraw tokens from pool after time", async () => {
            await time.setNextBlockTimestamp(finishTime)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 2)

            expect(poolData.poolInfo).to.deep.equal([0, constants.AddressZero, constants.AddressZero])
            expect(poolData.params.toString()).to.equal("")
        })

        it("should create new main coin pool", async () => {
            await time.setNextBlockTimestamp(finishTime)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 3)

            expect(poolData.poolInfo).to.deep.equal([poolId + 3, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 2)
        })

        it("should refresh old main coin pool left amount after withdraw", async () => {
            await time.setNextBlockTimestamp(finishTime)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 1)

            expect(poolData.poolInfo).to.deep.equal([poolId + 1, refundProvider.address, BUSD])
            expect(poolData.params[0]).to.equal(0)
            expect(poolData.params[1]).to.equal(finishTime)
        })

        it("should create new main coin pool with half tokens", async () => {
            await time.setNextBlockTimestamp(startTime + halfTime)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 3)

            expect(poolData.poolInfo).to.deep.equal([poolId + 3, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 4)
        })
    })

    describe("Refund Pool", async () => {
        it("the user receives the main coins without", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, receiver.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 2)
        })

        it("the project owner receives the main coins", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId + 2)
            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData.provider).to.equal(dealProvider.address)
            expect(poolData.poolInfo).to.deep.equal([poolId, projectOwner.address, token])
            expect(poolData.params[0]).to.equal(amount)
        })

        it("user withdraw the main coins", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId + 2)
            const [withdrawnAmount, isFinal] = await lockDealNFT.callStatic.withdraw(poolId + 1)
            expect(withdrawnAmount).to.equal(amount / 2)
            expect(isFinal).to.equal(true)
        })

        it("project owner withdraw tokens", async () => {
            await refundProvider.connect(projectOwner).createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId + 2)
            const [withdrawnAmount, isFinal] = await lockDealNFT.callStatic.withdraw(poolId)
            expect(withdrawnAmount).to.equal(amount)
            expect(isFinal).to.equal(true)
        })
     })
})