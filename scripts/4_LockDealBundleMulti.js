const hre = require("hardhat")

async function main() {
    // Get the contract factory
    const LockDealBundleMulti = await hre.ethers.getContractFactory("LockDealBundleMulti")
    const provider = "0x0000000000000000000000000000000000000000"

    // Deploy the contract
    const lockDealBundleMulti = await LockDealBundleMulti.deploy(provider)

    // Wait for the contract to be mined
    await baseProvider.deployed()

    console.log("Contract deployed to:", lockDealBundleMulti.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
