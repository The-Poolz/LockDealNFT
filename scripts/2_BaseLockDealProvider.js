const hre = require("hardhat")

async function main() {
    // Get the contract factory
    const BaseLockDealProvider = await hre.ethers.getContractFactory("BaseLockDealProvider")
    const nftContract = "0x0000000000000000000000000000000000000000"

    // Deploy the contract
    const baseProvider = await BaseLockDealProvider.deploy(nftContract)

    // Wait for the contract to be mined
    await baseProvider.deployed()

    console.log("Contract deployed to:", baseProvider.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})