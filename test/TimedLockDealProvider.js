const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")

describe("Base Lock Deal Provider", function (accounts) {
    let timedLockProvider, baseLockProvider, dealProvider, lockDealNFT
    let poolId, params
    let receiver
    let token, startTime, finishTime
    const amount = 10000

    before(async () => {
        ;[receiver] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const BaseLockProvider = await ethers.getContractFactory("BaseLockDealProvider")
        const TimedLockDealProvider = await ethers.getContractFactory("TimedLockDealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        lockDealNFT = await LockDealNFT.deploy()
        await lockDealNFT.deployed()
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        await dealProvider.deployed()
        baseLockProvider = await BaseLockProvider.deploy(lockDealNFT.address, dealProvider.address)
        await baseLockProvider.deployed()
        timedLockProvider = await TimedLockDealProvider.deploy(lockDealNFT.address, baseLockProvider.address)
        await timedLockProvider.deployed()
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await token.deployed()
        await token.approve(timedLockProvider.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(baseLockProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedLockProvider.address, true)
    })

    beforeEach(async () => {
        let date = new Date()
        date.setDate(date.getDate() + 1)
        startTime = Math.floor(date.getTime() / 1000)
        date.setDate(date.getDate() + 7)
        finishTime = Math.floor(date.getTime() / 1000)
        params = [amount, startTime, finishTime, amount]
        poolId = await lockDealNFT.totalSupply()
        await timedLockProvider.createNewPool(receiver.address, token.address, params)
    })

    it("should check deal provider address", async () => {
        const provider = await timedLockProvider.dealProvider()
        expect(provider.toString()).to.equal(baseLockProvider.address)
    })

    it("should check timed provider data after creation", async () => {
        const timedData = await timedLockProvider.poolIdToTimedDeal(poolId)
        expect(timedData.finishTime).to.equal(finishTime)
        expect(timedData.startAmount.toString()).to.equal(amount.toString())
    })

    it("should check contract token balance", async () => {
        const oldBal = await token.balanceOf(timedLockProvider.address)
        await timedLockProvider.createNewPool(receiver.address, token.address, params)
        expect(await token.balanceOf(timedLockProvider.address)).to.equal(parseInt(oldBal) + amount)
    })

    // it("should revert zero owner address", async () => {
    //     await expect(
    //         timedLockProvider.createNewPool(receiver.address, constants.AddressZero, params)
    //     ).to.be.revertedWith("Zero Address is not allowed")
    // })

    it("should revert zero token address", async () => {
        await expect(timedLockProvider.createNewPool(constants.AddressZero, token.address, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    // it("should revert zero amount", async () => {
    //     const params = ["0", startTime, finishTime, "0"]
    //     await expect(timedLockProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
    //         "amount should be greater than 0"
    //     )
    // })

    describe("Timed Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            const data = await timedLockProvider.poolIdToTimedDeal(poolId)
            expect(data.startAmount.toString()).to.equal((amount / 2).toString())
            expect(data.finishTime.toString()).to.equal((finishTime).toString())
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            const data = await timedLockProvider.poolIdToTimedDeal(parseInt(poolId) + 1)
            expect(data.startAmount.toString()).to.equal((amount / 2).toString())
            expect(data.finishTime.toString()).to.equal(finishTime.toString())
        })
    })
})
