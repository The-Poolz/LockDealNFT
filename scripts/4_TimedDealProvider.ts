import { deployed } from "../test/helper"
import { TimedDealProvider } from "../typechain-types"

async function main() {
    const lockDealNFT = "0x57e0433551460e85dfC5a5DdafF4DB199D0F960A" // replace with your lockDealNFT address
    const lockProvider = "0xD5dF3f41Cc1Df2cc42F3b683dD71eCc38913e0d6" // replace with your lockProvider address
    const timedDealProvider: TimedDealProvider = await deployed("TimedDealProvider", lockDealNFT, lockProvider)
    console.log(`Contract deployed to ${timedDealProvider.address}`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
