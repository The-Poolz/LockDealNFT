const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")

describe("Base Lock Deal Provider", function (accounts) {
    let dealProvider, lockDealNFT, poolId
    let notOwner, receiver
    let token, poolData, params
    const amount = 10000

    before(async () => {
        ;[notOwner, receiver] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        lockDealNFT = await LockDealNFT.deploy()
        await lockDealNFT.deployed()
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await dealProvider.deployed()
        await token.deployed()
        await token.approve(dealProvider.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        poolId = await lockDealNFT.totalSupply()
        params = [amount]
        await dealProvider.createNewPool(receiver.address, token.address, params)
    })

    it("should check pool data", async () => {
        poolData = await dealProvider.poolIdToDeal(poolId.toString())
        expect(poolData[0].toString()).to.equal(token.address)
        expect(poolData[1].toString()).to.equal(amount.toString())
    })

    it("should check pool creation events", async () => {
        const tx = await dealProvider.createNewPool(receiver.address, token.address, params)
        await tx.wait()
        const events = await dealProvider.queryFilter("NewPoolCreated")
        expect(events[events.length - 1].args.poolInfo.poolId).to.equal(parseInt(poolId) + 1)
        expect(events[events.length - 1].args.poolInfo.token).to.equal(token.address)
        expect(events[events.length - 1].args.poolInfo.owner).to.equal(receiver.address)
        expect(events[events.length - 1].args.params[0]).to.equal(amount) //assuming amount is at index 0 in the params array
    })

    it("should check contract token balance", async () => {
        const oldBal = await token.balanceOf(dealProvider.address)
        await dealProvider.createNewPool(receiver.address, token.address, params)
        expect(await token.balanceOf(dealProvider.address)).to.equal(parseInt(oldBal) + amount)
    })

    it("should revert zero owner address", async () => {
        await expect(dealProvider.createNewPool(receiver.address, constants.AddressZero, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero token address", async () => {
        await expect(dealProvider.createNewPool(constants.AddressZero, token.address, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero amount", async () => {
        const params = ["0"]
        await expect(dealProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
            "amount should be greater than 0"
        )
    })

    // it("should withdraw tokens from pool", async () => {
    //     await ethers.provider.send("evm_increaseTime", [startTime])
    //     await ethers.provider.send("evm_mine")
    //     await baseLockProvider.withdraw(itemId)
    //     poolData = await baseLockProvider.itemIdToDeal(itemId.toString())
    //     expect(poolData[1]).to.equal(0)
    // })

    // it("should revert twice withdrawing", async () => {
    //     await ethers.provider.send("evm_increaseTime", [startTime])
    //     await ethers.provider.send("evm_mine")
    //     await baseLockProvider.withdraw(itemId)
    //     await expect(baseLockProvider.withdraw(itemId)).to.be.revertedWith("amount should be greater than 0")
    // })

    // it("revert invalid owner", async () => {
    //     const notOwnerSigner = ethers.provider.getSigner(notOwner.address)
    //     const baseLockProviderWithNotOwner = baseLockProvider.connect(notOwnerSigner)
    //     await expect(baseLockProviderWithNotOwner.withdraw(itemId)).to.be.revertedWith("Not the owner of the pool")
    // })

    // it("should split half pool", async () => {
    //     await baseLockProvider.split(itemId, amount / 2, owner.address)
    //     poolData = await baseLockProvider.itemIdToDeal(itemId.toString())
    //     expect(poolData[0].toString()).to.equal(token.address)
    //     expect(poolData[1].toString()).to.equal((amount / 2).toString())
    //     expect(poolData[2].toString()).to.equal(startTime.toString())
    // })
})
