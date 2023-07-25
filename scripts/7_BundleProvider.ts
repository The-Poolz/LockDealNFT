import { deployed } from "../test/helper"
import { BundleProvider } from "../typechain-types"

async function main() {
    const lockDealNFT = "0x57e0433551460e85dfC5a5DdafF4DB199D0F960A" // replace with your lockDealNFT address
    const bundleProvider: BundleProvider = await deployed("BundleProvider", lockDealNFT)
    console.log(`Contract deployed to ${bundleProvider.address}`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
