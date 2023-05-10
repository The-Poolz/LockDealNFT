const { assert } = require("chai")
const truffleAssert = require("truffle-assertions")
const constants = require("@openzeppelin/test-helpers/src/constants")

const BaseProvider = artifacts.require("BaseLockDealProvider")
const NFTToken = artifacts.require("LockDealNFT")
const ERC20Token = artifacts.require("ERC20Token")

contract("Base Lock Deal Provider", (accounts) => {
    let baseProvider, nftToken, erc20Token
    let itemId, startTime
    let poolOwner = accounts[2]
    const amount = "10000"

    before(async () => {
        nftToken = await NFTToken.new()
        baseProvider = await BaseProvider.new(nftToken.address)
        erc20Token = await ERC20Token.new("TEST token", "TEST")
        await nftToken.setApprovedProvider(baseProvider.address, true)
        await erc20Token.approve(baseProvider.address, constants.MAX_UINT256)
    })

    beforeEach(async () => {
        date = new Date()
        date.setDate(date.getDate() + 1)
        startTime = Math.floor(date.getTime() / 1000)
        await baseProvider.createNewPool(poolOwner, erc20Token.address, amount, startTime)
        itemId = await nftToken.totalSupply()
    })

    it("check currect NFT token address", async () => {
        const nftAddress = await baseProvider.nftContract()
        assert.equal(nftToken.address, nftAddress.toString())
    })

    it("check events from pool creation", async () => {
        const tx = await baseProvider.createNewPool(poolOwner, erc20Token.address, amount, startTime)
        assert.equal(erc20Token.address, tx.logs[0].args.token)
        assert.equal(amount, tx.logs[0].args.amount)
        assert.equal(startTime, tx.logs[0].args.startTime)
    })

    it("check saved data from pool creation", async () => {
        const poolData = await baseProvider.itemIdToDeal(itemId.toString())
        assert.equal(erc20Token.address, poolData.tokenAddress)
        assert.equal(amount, poolData.amount)
        assert.equal(startTime.toString(), poolData.startTime.toString())
    })
})
