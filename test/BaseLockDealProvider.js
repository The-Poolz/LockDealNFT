const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")

describe("Base Lock Deal Provider", function (accounts) {
    let baseLockProvider, dealProvider, lockDealNFT, poolId, params
    let receiver
    let token, startTime
    const amount = 10000

    before(async () => {
        ;[receiver, newOwner] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const BaseLockProvider = await ethers.getContractFactory("BaseLockDealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        lockDealNFT = await LockDealNFT.deploy()
        await lockDealNFT.deployed()
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        await dealProvider.deployed()
        baseLockProvider = await BaseLockProvider.deploy(lockDealNFT.address, dealProvider.address)
        await baseLockProvider.deployed()
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await token.deployed()
        await token.approve(baseLockProvider.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(baseLockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        let date = new Date()
        date.setDate(date.getDate() + 1)
        startTime = Math.floor(date.getTime() / 1000)
        params = [amount, startTime]
        poolId = await lockDealNFT.totalSupply()
        await baseLockProvider.createNewPool(receiver.address, token.address, params)
    })

    it("should check deal provider address", async () => {
        const provider = await baseLockProvider.dealProvider()
        expect(provider.toString()).to.equal(dealProvider.address)
    })

    it("should check base provider data after creation", async () => {
        const poolStartTime = await baseLockProvider.startTimes(poolId)
        expect(poolStartTime).to.equal(startTime)
    })

    it("should revert zero owner address", async () => {
        await expect(
            baseLockProvider.createNewPool(receiver.address, constants.AddressZero, params)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert zero token address", async () => {
        await expect(baseLockProvider.createNewPool(constants.AddressZero, token.address, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    // it("should revert zero amount", async () => {
    //     const params = ["0", startTime]
    //     await expect(baseLockProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
    //         "amount should be greater than 0"
    //     )
    // })

    describe("Base Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            const data = await baseLockProvider.startTimes(poolId)
            expect(data.toString()).to.equal(startTime.toString())
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            const data = await baseLockProvider.startTimes(parseInt(poolId) + 1)
            expect(data.toString()).to.equal(startTime.toString())
        })
    })

    describe("Base Deal Withdraw", () => {
        it("should return withdrawAmount value", async () => {
            const withdrawnAmount = await lockDealNFT.callStatic.withdraw(poolId)
            expect(withdrawnAmount.toString()).to.equal(amount.toString())
        })

        it("should return zero if startTime > block.timestamp", async () => {
            const withdrawnAmount = await lockDealNFT.callStatic.withdraw(poolId)
            expect(withdrawnAmount.toString()).to.equal(amount.toString())
        })
    })
})
