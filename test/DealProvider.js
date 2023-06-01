const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")

describe("Deal Provider", function (accounts) {
    let dealProvider, lockDealNFT, poolId
    let receiver, newOwner
    let token, poolData, params
    const amount = 10000

    before(async () => {
        ;[receiver, newOwner] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        const MockVaultManager = await ethers.getContractFactory("MockVaultManager")
        const mockVaultManagger = await MockVaultManager.deploy()
        await mockVaultManagger.deployed()
        lockDealNFT = await LockDealNFT.deploy(mockVaultManagger.address)
        await lockDealNFT.deployed()
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await dealProvider.deployed()
        await token.deployed()
        await token.approve(dealProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManagger.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        poolId = await lockDealNFT.totalSupply()
        params = [amount]
        await dealProvider.createNewPool(receiver.address, token.address, params)
    })

    it("should get pool data", async () => {
        poolData = await dealProvider.getData(poolId);
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
        expect(poolData.params[0]).to.equal(amount);
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

    describe("Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)

            poolData = await dealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)

            poolData = await dealProvider.getData(parseInt(poolId) + 1);
            expect(poolData.poolInfo).to.deep.equal([parseInt(poolId) + 1, newOwner.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
        })
    })

    describe("Deal Withdraw", () => {
        it("should return withdrawAmount and isFinal values", async () => {
            const [withdrawnAmount, isFinal] = await lockDealNFT.callStatic.withdraw(poolId)
            expect(withdrawnAmount.toString()).to.equal(amount.toString())
            expect(isFinal).to.equal(true)
        })

        it("should check data in pool after withdraw", async () => {
            await lockDealNFT.withdraw(poolId)
            
            poolData = await dealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(0);
        })

        it("should check events after withdraw", async () => {
            poolId = await lockDealNFT.totalSupply()
            const tx = await lockDealNFT.withdraw(poolId)
            await tx.wait()
            const events = await dealProvider.queryFilter("TokenWithdrawn")
            expect(events[events.length - 1].args.poolId.toString()).to.equal(poolId.toString())
            expect(events[events.length - 1].args.owner.toString()).to.equal(receiver.address.toString())
            expect(events[events.length - 1].args.withdrawnAmount.toString()).to.equal(amount.toString())
            expect(events[events.length - 1].args.leftAmount.toString()).to.equal("0".toString())
        })
    })
})
