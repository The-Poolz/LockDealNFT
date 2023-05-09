const baseLockDealProvider = artifacts.require("BaseLockDealProvider")
const nftContract = "0x0000000000000000000000000000000000000000"

module.exports = function (deployer) {
    deployer.deploy(baseLockDealProvider, nftContract)
}
