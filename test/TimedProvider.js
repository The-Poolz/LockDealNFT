const { assert } = require("chai")
const truffleAssert = require("truffle-assertions")
const constants = require("@openzeppelin/test-helpers/src/constants")

const TimedProvider = artifacts.require("TimedLockDealProvider")
const NFTToken = artifacts.require("LockDealNFT")
const ERC20Token = artifacts.require("ERC20Token")

contract("Timed Lock Provider", (accounts) => {
    let timedProvider, nftToken, erc20Token
    let itemId, startTime, finishTime
    let poolOwner = accounts[2]
    const amount = "10000"

    before(async () => {
        nftToken = await NFTToken.new()
        timedProvider = await TimedProvider.new(nftToken.address)
        erc20Token = await ERC20Token.new("TEST token", "TEST")
        await nftToken.setApprovedProvider(timedProvider.address, true)
        await erc20Token.approve(timedProvider.address, constants.MAX_UINT256)
    })
})
