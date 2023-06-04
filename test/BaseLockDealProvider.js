const { expect } = require("chai")
const { constants } = require("ethers")
const { deployed } = require("./helper")
const helpers = require("@nomicfoundation/hardhat-network-helpers")

describe("Base Lock Deal Provider", function (accounts) {
    let baseLockProvider, dealProvider, lockDealNFT, poolId, params
    let receiver
    let token, startTime
    const amount = 10000

    before(async () => {
        ;[receiver, newOwner] = await ethers.getSigners()
        const mockVaultManagger = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManagger.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        baseLockProvider = await deployed("BaseLockDealProvider", lockDealNFT.address, dealProvider.address)
        await token.approve(baseLockProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManagger.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(baseLockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        startTime = await helpers.time.latest()
        params = [amount, startTime]
        poolId = parseInt(await lockDealNFT.totalSupply())
        await baseLockProvider.createNewPool(receiver.address, token.address, params)
    })

    it("should check deal provider address", async () => {
        const provider = await baseLockProvider.dealProvider()
        expect(provider.toString()).to.equal(dealProvider.address)
    })

    it("should check cascade pool creation events", async () => {
        const tx = await baseLockProvider.createNewPool(receiver.address, token.address, params)
        await tx.wait()
        const event = await dealProvider.queryFilter("NewPoolCreated")
        expect(event[event.length - 1].args.poolInfo.poolId).to.equal(poolId + 1)
        expect(event[event.length - 1].args.poolInfo.token).to.equal(token.address)
        expect(event[event.length - 1].args.poolInfo.owner).to.equal(receiver.address)
        expect(event[event.length - 1].args.params[0]).to.equal(amount)
    })

    it("should get base provider data after creation", async () => {       
        poolData = await baseLockProvider.getData(poolId);
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
        expect(poolData.params[0]).to.equal(amount);
        expect(poolData.params[1]).to.equal(startTime);
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

    it("should revert zero amount", async () => {
        const params = ["0", startTime]
        await expect(baseLockProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
            "amount should be greater than 0"
        )
    })

    describe("Base Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            
            poolData = await baseLockProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
            expect(poolData.params[1]).to.equal(startTime);
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)

            poolData = await baseLockProvider.getData(parseInt(poolId) + 1);
            expect(poolData.poolInfo).to.deep.equal([parseInt(poolId) + 1, newOwner.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
            expect(poolData.params[1]).to.equal(startTime);
        })
    })

    describe("Base Deal Withdraw", () => {
        it("should withdraw tokens", async () => {
            await helpers.time.increase(3600)
            await lockDealNFT.withdraw(poolId)
            
            poolData = await baseLockProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, constants.AddressZero, token.address]);
            expect(poolData.params[0]).to.equal(0);
            expect(poolData.params[1]).to.equal(startTime);
        })
    })
})
