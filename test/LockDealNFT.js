const { expect } = require("chai")
const { ethers } = require("hardhat")
const { constants } = require("ethers")

describe("LockDealNFT", function (accounts) {
    let lockDealNFT, poolId, token
    let provider, notOwner, receiver

    before(async () => {
        ;[notOwner, receiver] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        lockDealNFT = await LockDealNFT.deploy()
        provider = await DealProvider.deploy(lockDealNFT.address)
        await lockDealNFT.deployed()
        await lockDealNFT.setApprovedProvider(provider.address, true)
        await token.approve(provider.address, constants.MaxUint256)
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
        await lockDealNFT.setApprovedProvider(provider.address, true)
        expect(await lockDealNFT.approvedProviders(provider.address)).to.be.true
    })

    it("should mint new token", async () => {
        await provider.createNewPool(receiver.address, token.address, ["1000"])
        expect(await lockDealNFT.totalSupply()).to.equal(parseInt(poolId) + 1)
    })

    it("only provider can mint", async () => {
        await expect(lockDealNFT.connect(notOwner).mint(receiver.address)).to.be.revertedWith("Provider not approved")
    })
})
