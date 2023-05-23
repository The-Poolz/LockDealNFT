const { expect } = require("chai")
const { ethers } = require("hardhat")
const { constants } = require("ethers")

describe("LockDealNFT", function (accounts) {
    let lockDealNFT, poolId, token
    let provider, notOwner, receiver

    before(async () => {
        ;[notOwner, receiver, newOwner] = await ethers.getSigners()
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
        await token.approve(dealProvider.address, constants.MaxUint256)
        await token.approve(baseLockProvider.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(baseLockProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedLockProvider.address, true)
    })

    beforeEach(async () => {
        poolId = await lockDealNFT.totalSupply()
    })

    it("check NFT name", async () => {
        expect(await lockDealNFT.name()).to.equal("LockDealNFT")
    })

    it("check NFT symbol", async () => {
        expect(await lockDealNFT.symbol()).to.equal("LDNFT")
    })

    it("should set provider address", async () => {
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        expect(await lockDealNFT.approvedProviders(dealProvider.address)).to.be.true
    })

    it("should mint new token", async () => {
        await dealProvider.createNewPool(receiver.address, token.address, ["1000"])
        expect(await lockDealNFT.totalSupply()).to.equal(parseInt(poolId) + 1)
    })

    it("only provider can mint", async () => {
        await expect(lockDealNFT.connect(notOwner).mint(receiver.address)).to.be.revertedWith("Provider not approved")
    })

    describe("Split Amount", () => {
        let amount = 10000
        let poolId, params

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
})
