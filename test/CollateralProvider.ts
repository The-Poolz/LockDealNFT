import { MockVaultManager } from "../typechain-types"
import { CollateralProvider } from "../typechain-types/contracts/CollateralProvider"
import { DealProvider } from "../typechain-types/contracts/DealProvider"
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT"
import { MockProvider } from "../typechain-types/contracts/test/MockProvider"
import { deployed, token } from "./helper"
import { time } from "@nomicfoundation/hardhat-network-helpers"
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
    let halfTime: number
    const amount = 100000

    before(async () => {
        ;[receiver, projectOwner] = await ethers.getSigners()
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
        halfTime = (await time.latest()) + 7 * ONE_DAY // plus 7 days
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
        const mainCoinCollectorId = poolId + 1;
        const mainCoinHolderId = poolId + 3
        await mockProvider.handleWithdraw(poolId, amount / 2)
        let poolData = await lockDealNFT.getData(mainCoinHolderId)
        expect(poolData.params[0]).to.equal(amount / 2)
        poolData = await lockDealNFT.getData(mainCoinCollectorId)
        expect(poolData.params[0]).to.equal(amount / 2)
    })
})
