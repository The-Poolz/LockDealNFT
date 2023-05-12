const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")

describe("Timed LockDeal Provider", function (accounts) {
    let timedLockProvider, lockDealNFT, itemId
    let owner, notOwner, receiver
    let token, startTime, finishTime, poolData
    const amount = 10000

    before(async () => {
        ;[owner, notOwner, receiver] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const TimedLockDealProvider = await ethers.getContractFactory("TimedLockDealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        lockDealNFT = await LockDealNFT.deploy()
        await lockDealNFT.deployed()
        timedLockProvider = await TimedLockDealProvider.deploy(lockDealNFT.address)
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await timedLockProvider.deployed()
        await token.deployed()
        await token.approve(timedLockProvider.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(timedLockProvider.address, true)
    })

    beforeEach(async () => {
        let date = new Date()
        date.setDate(date.getDate() + 1)
        startTime = Math.floor(date.getTime() / 1000)
        date.setDate(date.getDate() + 7)
        finishTime = Math.floor(date.getTime() / 1000)
        await timedLockProvider.createNewPool(token.address, amount, startTime, finishTime, receiver.address)
        itemId = await lockDealNFT.totalSupply()
    })

    it("should check deal pool data", async () => {
        poolData = await timedLockProvider.itemIdToDeal(itemId.toString())
        expect(poolData[0].toString()).to.equal(token.address)
        expect(poolData[1].toString()).to.equal(amount.toString())
        expect(poolData[2].toString()).to.equal(startTime.toString())
    })

    it("should check timed deal pool data", async () => {
        const data = await timedLockProvider.poolIdToTimedDeal(itemId.toString())
        expect(data[0].toString()).to.equal(finishTime.toString())
        expect(data[1].toString()).to.equal("0")
    })
})
