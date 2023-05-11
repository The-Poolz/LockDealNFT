const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("LockDealNFT", function (accounts) {
    let lockDealNFT, itemId
    let provider, notOwner, receiver

    before(async () => {
        ;[provider, notOwner, receiver] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        lockDealNFT = await LockDealNFT.deploy()
        await lockDealNFT.deployed()
        await lockDealNFT.setApprovedProvider(provider.address, true)
    })

    beforeEach(async () => {
        itemId = await lockDealNFT.totalSupply()
    })

    it("check NFT name", async () => {
        expect(await lockDealNFT.name()).to.equal("LockDealNFT")
    })

    it("check NFT symbol", async () => {
        expect(await lockDealNFT.symbol()).to.equal("LDNFT")
    })

    it("should set provider address", async () => {
        await lockDealNFT.setApprovedProvider(provider.address, true)
        expect(await lockDealNFT.approvedProviders(provider.address)).to.be.true
    })

    it("should mint new token", async () => {
        await lockDealNFT.connect(receiver.address)
        await lockDealNFT.mint(receiver.address)
        expect(await lockDealNFT.totalSupply()).to.equal(parseInt(itemId) + 1)
    })
})
