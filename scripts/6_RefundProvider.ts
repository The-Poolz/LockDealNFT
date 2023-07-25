import { deployed } from "../test/helper"
import { RefundProvider } from "../typechain-types"

async function main() {
    const lockDealNFT = "0x57e0433551460e85dfC5a5DdafF4DB199D0F960A" // replace with your lockDealNFT address
    const collateralProvider = "0xDB65cE03690e7044Ac12F5e2Ab640E7A355E9407" // replace with your collateralProvider address
    const refundProvider: RefundProvider = await deployed("RefundProvider", lockDealNFT, collateralProvider)
    console.log(`Contract deployed to ${refundProvider.address}`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
