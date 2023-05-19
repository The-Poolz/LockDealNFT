const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")

describe("Base Lock Deal Provider", function (accounts) {
    let timedLockProvider, baseLockProvider, dealProvider, lockDealNFT
    let poolId, params
    let owner, notOwner, receiver
    let token, startTime, finishTime
    const amount = 10000

    before(async () => {
        ;[owner, notOwner, receiver] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const BaseLockProvider = await ethers.getContractFactory("BaseLockDealProvider")
        const TimedLockDealProvider = await ethers.getContractFactory("TimedLockDealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        lockDealNFT = await LockDealNFT.deploy()
        await lockDealNFT.deployed()
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        await dealProvider.deployed()
        baseLockProvider = await BaseLockProvider.deploy(dealProvider.address)
        await baseLockProvider.deployed()
        timedLockProvider = await TimedLockDealProvider.deploy(baseLockProvider.address)
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
        params = [amount, startTime, finishTime]
        poolId = await lockDealNFT.totalSupply()
        await timedLockProvider.createNewPool(receiver.address, token.address, params)
    })

    it("should check deal provider address", async () => {
        const provider = await timedLockProvider.dealProvider()
        expect(provider.toString()).to.equal(baseLockProvider.address)
    })

    it("should check deal provider data after baseLockProvider creation", async () => {
        dealData = await dealProvider.poolIdToDeal(poolId.toString())
        expect(dealData[0].toString()).to.equal(token.address)
        expect(dealData[1].toString()).to.equal(amount.toString())
    })

    it("should check base provider data after creation", async () => {
        const poolStartTime = await baseLockProvider.startTimes(poolId)
        expect(poolStartTime).to.equal(startTime)
    })

    it("should check timed provider data after creation", async () => {
        const timedData = await timedLockProvider.poolIdToTimedDeal(poolId)
        expect(timedData.finishTime).to.equal(finishTime)
        expect(timedData.withdrawnAmount).to.equal(0)
    })

    it("should check pool creation events", async () => {
        const tx = await timedLockProvider.createNewPool(receiver.address, token.address, params)
        await tx.wait()
        const events = await dealProvider.queryFilter("NewPoolCreated")
        expect(events[events.length - 1].args.poolInfo.poolId).to.equal(parseInt(poolId) + 1)
        expect(events[events.length - 1].args.poolInfo.token).to.equal(token.address)
        expect(events[events.length - 1].args.poolInfo.owner).to.equal(receiver.address)
        expect(events[events.length - 1].args.params[0]).to.equal(amount)
        expect(events[events.length - 1].args.params[1]).to.equal(startTime)
        expect(events[events.length - 1].args.params[2]).to.equal(finishTime)
    })

    it("should check contract token balance", async () => {
        const oldBal = await token.balanceOf(timedLockProvider.address)
        await timedLockProvider.createNewPool(receiver.address, token.address, params)
        expect(await token.balanceOf(timedLockProvider.address)).to.equal(parseInt(oldBal) + amount)
    })

    it("should revert zero owner address", async () => {
        await expect(
            timedLockProvider.createNewPool(receiver.address, constants.AddressZero, params)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert zero token address", async () => {
        await expect(timedLockProvider.createNewPool(constants.AddressZero, token.address, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero amount", async () => {
        const params = ["0", startTime, finishTime]
        await expect(timedLockProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
            "amount should be greater than 0"
        )
    })
})
