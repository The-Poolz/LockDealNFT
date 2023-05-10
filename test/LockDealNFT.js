const { assert } = require("chai")
const truffleAssert = require("truffle-assertions")

const LockDealNFT = artifacts.require("LockDealNFT")

contract("LockDealNFT", (accounts) => {
    let lockDealNFT, itemId
    const provider = accounts[0]
    const notOwner = accounts[1]
    const receiver = accounts[2]

    before(async () => {
        lockDealNFT = await LockDealNFT.new()
        await lockDealNFT.setApprovedProvider(provider, true)
    })

    beforeEach(async () => {
        itemId = await lockDealNFT.totalSupply()
    })

    it("check NFT name", async () => {
        assert.equal("LockDealNFT", (await lockDealNFT.name()).toString())
    })

    it("check NFT symbol", async () => {
        assert.equal("LDNFT", (await lockDealNFT.symbol()).toString())
    })

    it("should set provider address", async () => {
        await lockDealNFT.setApprovedProvider(provider, true)
        const status = await lockDealNFT.approvedProviders(provider)
        assert.equal(true, status)
    })

    it("should mint new token", async () => {
        await lockDealNFT.mint(receiver, { from: provider })
        const index = await lockDealNFT.totalSupply()
        assert.equal((parseInt(itemId) + 1).toString(), index.toString())
    })

    it("only owner can set provider rights", async () => {
        await truffleAssert.reverts(
            lockDealNFT.setApprovedProvider(provider, true, { from: notOwner }),
            "Ownable: caller is not the owner"
        )
    })

    it("not provider can't mint", async () => {
        await truffleAssert.reverts(lockDealNFT.mint(receiver, { from: notOwner }), "Provider not approved")
    })
})
