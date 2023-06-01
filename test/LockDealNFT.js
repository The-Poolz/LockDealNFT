const { expect } = require("chai")
const { ethers } = require("hardhat")
const { constants } = require("ethers")
const { deployed } = require("./helper")

describe("LockDealNFT", function (accounts) {
    let lockDealNFT, poolId, token, mockVaultManager
    let notOwner, receiver, newOwner

    before(async () => {
        ;[notOwner, receiver, newOwner] = await ethers.getSigners()
        mockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        await token.approve(dealProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManager.address, constants.MaxUint256)
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

    it("only provider can mint", async () => {
        await expect(
            lockDealNFT.connect(notOwner).mint(receiver.address, notOwner.address, token.address, 10)
        ).to.be.revertedWith("Provider not approved")
    })

    it("should revert not approved amount", async () => {
        await token.approve(mockVaultManager.address, "0")
        await expect(dealProvider.createNewPool(receiver.address, token.address, ["1000"])).to.be.revertedWith(
            "Sending tokens not approved"
        )
        await token.approve(mockVaultManager.address, constants.MaxUint256)
    })
})
