const { expect } = require("chai")
const { ethers } = require("hardhat")
const { constants } = require("ethers")

describe("LockDealNFT", function (accounts) {
    let lockDealNFT, poolId, token, mockVaultManagger
    let notOwner, receiver, newOwner

    before(async () => {
        ;[notOwner, receiver, newOwner] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        const MockVaultManager = await ethers.getContractFactory("MockVaultManager")
        mockVaultManagger = await MockVaultManager.deploy()
        await mockVaultManagger.deployed()
        lockDealNFT = await LockDealNFT.deploy(mockVaultManagger.address)
        await lockDealNFT.deployed()
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        await dealProvider.deployed()
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await token.deployed()
        await token.approve(dealProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManagger.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
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

    it("should save provider address", async () => {
        await dealProvider.createNewPool(receiver.address, token.address, ["1000"])
        expect(await lockDealNFT.poolIdToProvider(poolId)).to.equal(dealProvider.address)
    })

    it("only provider can mint", async () => {
        await expect(
            lockDealNFT.connect(notOwner).mint(receiver.address, notOwner.address, token.address, 10)
        ).to.be.revertedWith("Provider not approved")
    })

    it("should revert not approved amount", async () => {
        await token.approve(mockVaultManagger.address, "0")
        await expect(dealProvider.createNewPool(receiver.address, token.address, ["1000"])).to.be.revertedWith(
            "Sending tokens not approved"
        )
        await token.approve(mockVaultManagger.address, constants.MaxUint256)
    })
})
