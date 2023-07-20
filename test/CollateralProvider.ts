import { MockVaultManager } from "../typechain-types"
import { CollateralProvider } from "../typechain-types"
import { DealProvider } from "../typechain-types"
import { LockDealNFT } from "../typechain-types"
import { MockProvider } from "../typechain-types"
import { deployed, token } from "./helper"
import { time, mine } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { constants } from "ethers"
import { ethers } from "hardhat"

describe("Collateral Provider", function () {
    let dealProvider: DealProvider
    let collateralProvider: CollateralProvider
    let lockDealNFT: LockDealNFT
    let mockProvider: MockProvider
    let poolId: number
    let params: [number, number]
    let receiver: SignerWithAddress
    let projectOwner: SignerWithAddress
    let finishTime: number
    const amount = 100000

    before(async () => {
        [receiver, projectOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        collateralProvider = await deployed("CollateralProvider", lockDealNFT.address, dealProvider.address)
        mockProvider = await deployed("MockProvider", lockDealNFT.address, collateralProvider.address)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(collateralProvider.address, true)
        await lockDealNFT.setApprovedProvider(mockProvider.address, true)
    })

    beforeEach(async () => {
        const ONE_DAY = 86400
        finishTime = (await time.latest()) + 14 * ONE_DAY // plus 14 days
        params = [amount, finishTime]
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await mockProvider.createNewPool(projectOwner.address, token, params)
    })

    it("should revert invalid zero address before creation", async () => {
        await expect(deployed("CollateralProvider", lockDealNFT.address, constants.AddressZero)).to.be.revertedWith(
            "invalid address"
        )
    })

    it("should register new collateral pool", async () => {
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.equal(collateralProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, projectOwner.address, token])
        expect(poolData.params[0]).to.equal(amount)
        expect(poolData.params[1]).to.equal(finishTime)
    })

    it("should create main coin deal provider pool", async () => {
        const poolData = await lockDealNFT.getData(poolId + 1)
        expect(poolData.provider).to.equal(dealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId + 1, collateralProvider.address, constants.AddressZero])
        expect(poolData.params[0]).to.equal(0)
    })

    it("should create token provider pool", async () => {
        const poolData = await lockDealNFT.getData(poolId + 2)
        expect(poolData.provider).to.equal(dealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId + 2, collateralProvider.address, constants.AddressZero])
        expect(poolData.params[0]).to.equal(0)
    })

    it("should revert invalid finish time", async () => {
        await expect(
            mockProvider.createNewPool(receiver.address, token, [amount, (await time.latest()) - 1])
        ).to.be.revertedWith("start time must be in the future")
    })

    it("should deposit tokens", async () => {
        await mockProvider.handleRefund(poolId, amount, amount / 2)
        const tokenCollectorId = poolId + 2
        const mainCoinHolderId = poolId + 3
        let poolData = await lockDealNFT.getData(tokenCollectorId)
        expect(poolData.params[0]).to.equal(amount)
        poolData = await lockDealNFT.getData(mainCoinHolderId)
        expect(poolData.params[0]).to.equal(amount / 2)
    })

    it("should deposit main coin", async () => {
        await mockProvider.handleWithdraw(poolId, amount / 2)
        const mainCoinCollectorId = poolId + 1
        const mainCoinHolderId = poolId + 3
        let poolData = await lockDealNFT.getData(mainCoinHolderId)
        expect(poolData.params[0]).to.equal(amount / 2)
        poolData = await lockDealNFT.getData(mainCoinCollectorId)
        expect(poolData.params[0]).to.equal(amount / 2)
    })

    it("only NFT can manage withdraw", async () => {
        await expect(collateralProvider.withdraw(constants.AddressZero, constants.AddressZero, poolId, [])).to.be.revertedWith("only NFT contract can call this function")
    })

    it("should withdraw before time main coins", async () => {
        await mockProvider.handleWithdraw(poolId, amount / 2)
        await lockDealNFT.connect(projectOwner)["safeTransferFrom(address,address,uint256)"](projectOwner.address, lockDealNFT.address, poolId)
        const newMainCoinHolderId = poolId + 4
        const poolData = await lockDealNFT.getData(newMainCoinHolderId)
        expect(poolData.poolInfo).to.deep.equal([newMainCoinHolderId, projectOwner.address, constants.AddressZero])
        expect(poolData.params[0]).to.equal(amount / 2)
    })

    it("should withdraw tokens before time", async () => {
        await mockProvider.handleRefund(poolId, amount / 2, amount / 2)
        await lockDealNFT.connect(projectOwner)["safeTransferFrom(address,address,uint256)"](projectOwner.address, lockDealNFT.address, poolId)
        const newTokenHolderId = poolId + 4
        const poolData = await lockDealNFT.getData(newTokenHolderId)
        expect(poolData.poolInfo).to.deep.equal([newTokenHolderId, projectOwner.address, constants.AddressZero])
        expect(poolData.params[0]).to.equal(amount / 2)
    })

    it("should withdraw main coins and tokens before time", async () => {
        await mockProvider.handleWithdraw(poolId, amount / 2)
        await mockProvider.handleRefund(poolId, amount / 2, amount / 2)
        await lockDealNFT.connect(projectOwner)["safeTransferFrom(address,address,uint256)"](projectOwner.address, lockDealNFT.address, poolId)
        const newMainCoinHolderId = poolId + 4
        const newTokenHolderId = poolId + 5
        // should create two pools with tokens and main coins
        const mainCoinPoolData = await lockDealNFT.getData(newMainCoinHolderId)
        expect(mainCoinPoolData.poolInfo).to.deep.equal([newMainCoinHolderId, projectOwner.address, constants.AddressZero])
        expect(mainCoinPoolData.params[0]).to.equal(amount / 2)
        const tokensPoolData = await lockDealNFT.getData(newTokenHolderId)
        expect(tokensPoolData.poolInfo).to.deep.equal([newTokenHolderId, projectOwner.address, constants.AddressZero])
        expect(tokensPoolData.params[0]).to.equal(amount / 2)
    })

    it("should transfer all pools to project owner after finish time", async () => {
        await time.setNextBlockTimestamp(finishTime + 1)
        await lockDealNFT.connect(projectOwner)["safeTransferFrom(address,address,uint256)"](projectOwner.address, lockDealNFT.address, poolId)
        const mainCoinCollectorId = poolId + 1
        const tokenCollectorId = poolId + 2
        const mainCoinHolderId = poolId + 3
        // check pools ownership
        let poolData = await lockDealNFT.getData(mainCoinCollectorId)
        expect(poolData.poolInfo).to.deep.equal([mainCoinCollectorId, projectOwner.address, constants.AddressZero])

        poolData = await lockDealNFT.getData(tokenCollectorId)
        expect(poolData.poolInfo).to.deep.equal([tokenCollectorId, projectOwner.address, constants.AddressZero])

        poolData = await lockDealNFT.getData(mainCoinHolderId)
        expect(poolData.poolInfo).to.deep.equal([mainCoinHolderId, projectOwner.address, constants.AddressZero])
    })

    it("should get zero amount before time", async () => {
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
        await mockProvider.handleWithdraw(poolId, amount / 2)
        const withdrawAmount = await lockDealNFT.getWithdrawableAmount(poolId)
        expect(withdrawAmount).to.equal(amount / 2)
    })
})
