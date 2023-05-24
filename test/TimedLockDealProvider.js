const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")
const helpers = require("@nomicfoundation/hardhat-network-helpers")

describe("Base Lock Deal Provider", function (accounts) {
    let timedLockProvider, baseLockProvider, dealProvider, lockDealNFT
    let timestamp, halfTime
    let poolId, params
    let receiver
    let token, startTime, finishTime
    const amount = 100000

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
        date.setDate(date.getDate())
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
            expect(data.finishTime.toString()).to.equal(finishTime.toString())
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            const data = await timedLockProvider.poolIdToTimedDeal(parseInt(poolId) + 1)
            expect(data.startAmount.toString()).to.equal((amount / 2).toString())
            expect(data.finishTime.toString()).to.equal(finishTime.toString())
        })

        it("should check event data after split", async () => {
            const tx = await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            await tx.wait()
            const events = await dealProvider.queryFilter("PoolSplit")
            expect(events[events.length - 1].args.poolId).to.equal(poolId)
            expect(events[events.length - 1].args.newPoolId).to.equal(parseInt(poolId) + 1)
            expect(events[events.length - 1].args.owner).to.equal(receiver.address)
            expect(events[events.length - 1].args.newOwner).to.equal(newOwner.address)
            expect(events[events.length - 1].args.splitLeftAmount).to.equal(amount / 2)
            expect(events[events.length - 1].args.newSplitLeftAmount).to.equal(amount / 2)
        })
    })

    describe("Timed Withdraw", () => {
        beforeEach(async () => {
            timestamp = await helpers.time.latest()
            halfTime = (finishTime - startTime) / 2
            await helpers.time.increase(halfTime)
        })

        it("should withdraw half tokens", async () => {
            const tx = await lockDealNFT.withdraw(poolId)
            await tx.wait()
            const events = await dealProvider.queryFilter("TokenWithdrawn")
            //expect(events[events.length - 1].args.leftAmount.toString()).to.equal((amount / 2).toString())
        })

        // it("should withdraw all tokens", async () => {
        //     await helpers.time.setNextBlockTimestamp(finishTime)
        //     const withdrawnAmount = await lockDealNFT.withdraw(poolId)
        //     //expect(withdrawnAmount.toString()).to.equal(amount.toString())
        // })
    })
})
