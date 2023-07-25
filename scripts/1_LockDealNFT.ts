import { deployed } from "../test/helper"
import { LockDealNFT } from "../typechain-types"

async function main() {
    const vaultManager = "0x2C7e92B7dD268C154c4de2558f4f32687863bB25" // replace with your vaultManager address
    const baseURI = "https://poolz.finance/"
    const lockDealNFT: LockDealNFT = await deployed("LockDealNFT", vaultManager, baseURI)
    console.log(`Contract deployed to ${lockDealNFT.address} with vaultManager ${vaultManager}`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
