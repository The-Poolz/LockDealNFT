import { MockVaultManager } from "../typechain-types"
import { DealProvider, IDealProvierEvents } from "../typechain-types/contracts/DealProvider"
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT"
import { LockDealProvider } from "../typechain-types/contracts/LockProvider"
import { RefundProvider } from "../typechain-types/contracts/RefundProvider/RefundProvider.sol"
import { ERC20Token } from "../typechain-types/poolz-helper-v2/contracts/token"
import { deployed } from "./helper"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { constants, BigNumber } from "ethers"

describe("Refund Provider", function () {
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
    let refundProvider: RefundProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let projectOwner: SignerWithAddress
    let token: ERC20Token
    let BUSD: ERC20Token
    let params: [number, number, number, number]
    let startTime: number
    const amount = 10000

    before(async () => {
        ;[receiver, projectOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        BUSD = await deployed("ERC20Token", "BUSD Token", "BUSD")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, lockProvider.address)
        await token.transfer(projectOwner.address, amount * 100)
        await BUSD.transfer(projectOwner.address, amount * 100)
        await token.connect(projectOwner).approve(mockVaultManager.address, constants.MaxUint256)
        await BUSD.connect(projectOwner).approve(mockVaultManager.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
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
            .createNewRefundPool(token.address, receiver.address, BUSD.address, lockProvider.address, params)
    })

    describe("Pool Creation", async () => {
        it("should return currect pool data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, refundProvider.address, token.address])
            expect(poolData.params[0]).to.equal(amount)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect main coin data after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, projectOwner.address, BUSD.address])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect data for user after creation", async () => {
            const poolData = await lockDealNFT.getData(poolId + 2)
            expect(poolData.poolInfo).to.deep.equal([poolId + 2, receiver.address, token.address])
            expect(poolData.params[0]).to.equal(amount)
            expect(poolData.params[1]).to.equal(startTime)
        })
    })

    describe("Split Pool", async () => {
        it("should return currect pool data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, refundProvider.address, token.address])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect pool main coin data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 1)
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, projectOwner.address, BUSD.address])
            expect(poolData.params[0]).to.equal(amount / 4)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return currect data for user after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 2)
            expect(poolData.poolInfo).to.deep.equal([poolId + 2, receiver.address, token.address])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return new pool data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)
            
            const poolData = await lockDealNFT.getData(poolId + 4)
            expect(poolData.poolInfo).to.deep.equal([poolId + 4, refundProvider.address, token.address])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return new pool main coin data after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 5)
            expect(poolData.poolInfo).to.deep.equal([poolId + 5, projectOwner.address, BUSD.address])
            expect(poolData.params[0]).to.equal(amount / 4)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should return new data for user after split", async () => {
            await lockDealNFT.split(poolId + 2, amount / 2, receiver.address)

            const poolData = await lockDealNFT.getData(poolId + 6)
            expect(poolData.poolInfo).to.deep.equal([poolId + 6, receiver.address, token.address])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
        })
    })

    describe("Withdraw Pool", async () => {
        it("should withdraw tokens from pool after time", async () => {
            await time.setNextBlockTimestamp(startTime + 1)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await refundProvider.getData(poolId + 2)

            expect(poolData.poolInfo).to.deep.equal([poolId + 2, constants.AddressZero, token.address])
            expect(poolData.params[0]).to.equal(0)
            expect(poolData.params[1]).to.equal(startTime)
        })

        it("should create new main coin pool after withdraw with zero startTime", async () => {
            await time.setNextBlockTimestamp(startTime + 1)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 3)

            expect(poolData.poolInfo).to.deep.equal([poolId + 3, projectOwner.address, BUSD.address])
            expect(poolData.params[0]).to.equal(amount / 2)
        })

        it("should refresh old main coin pool left amount after withdraw", async () => {
            await time.setNextBlockTimestamp(startTime + 1)
            await lockDealNFT.withdraw(poolId + 2)
            const poolData = await lockDealNFT.getData(poolId + 1)

            expect(poolData.poolInfo).to.deep.equal([poolId + 1, projectOwner.address, BUSD.address])
            expect(poolData.params[0]).to.equal(0)
            expect(poolData.params[1]).to.equal(startTime)
        })
    })

    describe("Refund Pool", async () => {
        it("should refund tokens from pool after time", async () => {
            //await lockDealNFT.safeTransferFrom(receiver.address, refundProvider.address, poolId + 2)
            //await lockDealNFT.connect(receiver.address).transferFrom(receiver.address, refundProvider.address, poolId + 2)
            await lockDealNFT["safeTransferFrom(address,address,uint256)"]
            await lockDealNFT.connect(receiver.address).safeTransferFrom(receiver.address, refundProvider.address, poolId + 2)
            //await lockDealNFT["safeTransferFrom(address,address,uint256)"].connect(receiver.address).(receiver.address, refundProvider.address, poolId + 2)
            console.log(receiver.address)
            console.log(projectOwner.address)
        })
    })
})
