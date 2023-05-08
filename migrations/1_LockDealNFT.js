const LockDealNFT = artifacts.require("LockDealNFT")

module.exports = function (deployer) {
    deployer.deploy(LockDealNFT)
}
