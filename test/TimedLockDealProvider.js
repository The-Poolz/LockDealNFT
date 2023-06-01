const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")
const helpers = require("@nomicfoundation/hardhat-network-helpers")

describe("Timed Lock Deal Provider", function (accounts) {
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
        const MockVaultManager = await ethers.getContractFactory("MockVaultManager")
        const mockVaultManagger = await MockVaultManager.deploy()
        await mockVaultManagger.deployed()
        lockDealNFT = await LockDealNFT.deploy(mockVaultManagger.address)
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
        await token.approve(mockVaultManagger.address, constants.MaxUint256)
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
        timestamp = await helpers.time.latest()
        halfTime = (finishTime - startTime) / 2
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

    it("should check cascade NewPoolCreated event", async () => {
        const tx = await timedLockProvider.createNewPool(receiver.address, token.address, params)
        await tx.wait()
        const event = await dealProvider.queryFilter("NewPoolCreated((uint256,address,address),uint256[])")
        const data = event[event.length - 1].args
        expect(data.poolInfo.poolId).to.equal(parseInt(poolId) + 1)
        expect(data.poolInfo.token).to.equal(token.address)
        expect(data.poolInfo.owner).to.equal(receiver.address)
        expect(data.params[0]).to.equal(amount)
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
        const params = ["0", startTime, finishTime, "0"]
        await expect(timedLockProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
            "amount should be greater than 0"
        )
    })

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

        it("should split after withdraw", async () => {
            await helpers.time.setNextBlockTimestamp(startTime + halfTime / 5) // 10% of time
            await lockDealNFT.withdraw(poolId)
            await lockDealNFT.split(poolId, parseInt(amount / 2), newOwner.address)
            const data = await timedLockProvider.poolIdToTimedDeal(parseInt(poolId) + 1)
            const oldPooldata = await timedLockProvider.poolIdToTimedDeal(parseInt(poolId))
            const dealData = await dealProvider.poolIdToDeal(parseInt(poolId) + 1)
            const oldPooldealData = await dealProvider.poolIdToDeal(parseInt(poolId))
            expect(data.startAmount.toString()).to.equal((amount / 2).toString())
            expect(data.finishTime.toString()).to.equal(finishTime.toString())
            expect(oldPooldata.startAmount.toString()).to.equal((amount / 2).toString())
            expect(oldPooldealData.leftAmount.toString()).to.equal((amount / 2 - amount / 10).toString())
            expect(dealData.leftAmount.toString()).to.equal((amount / 2).toString())
        })
    })

    describe("Timed Withdraw", () => {
        it("should withdraw 25% tokens", async () => {
            await helpers.time.setNextBlockTimestamp(startTime + halfTime / 2)
            await lockDealNFT.withdraw(poolId)
            const timedData = await timedLockProvider.poolIdToTimedDeal(poolId)
            const dealData = await dealProvider.poolIdToDeal(poolId)
            expect(timedData.startAmount.toString()).to.equal(amount.toString())
            expect(dealData.leftAmount.toString()).to.equal((amount - amount / 4).toString())
        })

        it("should withdraw half tokens", async () => {
            await helpers.time.setNextBlockTimestamp(startTime + halfTime)
            await lockDealNFT.withdraw(poolId)
            const dealData = await dealProvider.poolIdToDeal(poolId)
            expect(dealData.leftAmount.toString()).to.equal((amount / 2).toString())
        })

        it("should withdraw all tokens", async () => {
            await helpers.time.increaseTo(finishTime + halfTime)
            await lockDealNFT.withdraw(poolId)
            const dealData = await dealProvider.poolIdToDeal(poolId)
            expect(dealData.leftAmount.toString()).to.equal("0")
        })
    })
})
