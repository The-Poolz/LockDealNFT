const hre = require("hardhat")

async function main() {
    // Get the contract factory
    const TimedLockDealProvider = await hre.ethers.getContractFactory("TimedLockDealProvider")
    const nftContract = "0x0000000000000000000000000000000000000000"

    // Deploy the contract
    const timedProvider = await TimedLockDealProvider.deploy(nftContract)

    // Wait for the contract to be mined
    await baseProvider.deployed()

    console.log("Contract deployed to:", timedProvider.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
