const hre = require("hardhat")

async function main() {
    // Get the contract factory
    const LockDealNFT = await hre.ethers.getContractFactory("LockDealNFT")

    // Deploy the contract
    const lockDealNFT = await LockDealNFT.deploy()

    // Wait for the contract to be mined
    await lockDealNFT.deployed()

    console.log("Contract deployed to:", lockDealNFT.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
