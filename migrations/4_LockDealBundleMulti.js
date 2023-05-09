const lockDealBundleMulti = artifacts.require("LockDealBundleMulti")
const lockDealNFT = "0x0000000000000000000000000000000000000000"

module.exports = function (deployer) {
    deployer.deploy(lockDealBundleMulti, lockDealNFT)
}
