const lockDealNFT = artifacts.require("LockDealNFT")

module.exports = function (deployer) {
    deployer.deploy(lockDealNFT)
}
