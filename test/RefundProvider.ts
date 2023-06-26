import { MockVaultManager } from "../typechain-types"
import { DealProvider } from "../typechain-types/contracts/DealProvider"
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT"
import { LockDealProvider } from "../typechain-types/contracts/LockProvider"
import { RefundProvider } from "../typechain-types/contracts/RefundProvider/RefundProvider.sol"
import { deployed, token } from "./helper"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { constants } from "ethers"

describe("Refund Provider", function () {
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
    let refundProvider: RefundProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let projectOwner: SignerWithAddress
    let BUSD: string
    let params: [number, number, number, number]
    let startTime: number
    const amount = 10000

    before(async () => {
        [receiver, projectOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, lockProvider.address)
        BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.connect(projectOwner).setApprovalForAll(refundProvider.address, true)
    })

    //  /________________________________,-```-,
    //  | poolId = refundProvider        |     |
    //  | (poolId - 1) = LockDealProvider|     |
    //  | (poolId - 2) = data holder     |     |
    //  \_______________________________/_____/
    beforeEach(async () => {
        const ONE_DAY = 86400
        startTime = (await time.latest()) + ONE_DAY
        params = [amount, startTime, amount / 2, startTime]
        poolId = (await lockDealNFT.tokenIdCounter()).toNumber()
        await refundProvider
            .connect(projectOwner)
            .createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
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
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect data for user after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 2)
            expect(poolData.poolInfo).to.deep.equal([poolId + 2, receiver.address, token])
            expect(poolData.params[0]).to.equal(amount)
            expect(poolData.params[1]).to.equal(startTime)
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
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 4)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect data for user after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 2)
            expect(poolData.poolInfo).to.deep.equal([poolId + 2, receiver.address, token])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return new pool data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 3)
            expect(poolData.poolInfo).to.deep.equal([poolId + 3, refundProvider.address, token])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return new pool main coin data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 4)
            expect(poolData.poolInfo).to.deep.equal([poolId + 4, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 4)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return new data for user after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 5)
            expect(poolData.poolInfo).to.deep.equal([poolId + 5, receiver.address, token])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })
    })

    describe("Withdraw Pool", async () => {
        it("should withdraw tokens from pool after time", async () => {
            await time.setNextBlockTimestamp(startTime + 1)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await refundProvider.getData(poolId + 2)

            expect(poolData.poolInfo).to.deep.equal([0, constants.AddressZero, constants.AddressZero])
            expect(poolData.params.toString()).to.equal("")
        })

        it("should create new main coin pool after withdraw with zero startTime", async () => {
            await time.setNextBlockTimestamp(startTime + 1)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 3)

            expect(poolData.poolInfo).to.deep.equal([poolId + 3, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 2)
        })

        it("should refresh old main coin pool left amount after withdraw", async () => {
            await time.setNextBlockTimestamp(startTime + 1)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 1)

            expect(poolData.poolInfo).to.deep.equal([poolId + 1, projectOwner.address, BUSD])
            expect(poolData.params[0]).to.equal(0)
            expect(poolData.params[1]).to.equal(startTime)
        })
    })

    describe("Refund Pool", async () => {
        it("the user receives the main coins without", async () => {
            await refundProvider
                .connect(projectOwner)
                .createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
            await lockDealNFT.connect(receiver)["safeTransferFrom(address,address,uint256)"](receiver.address, refundProvider.address, poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, receiver.address, BUSD])
            expect(poolData.params[0]).to.equal(amount / 2)
        })

        it("the project owner receives the main coins", async () => {
            await refundProvider
                .connect(projectOwner)
                .createNewRefundPool(token, receiver.address, BUSD, lockProvider.address, params)
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
