import { deployed } from "../test/helper"
import { LockDealNFT, DealProvider, LockDealProvider, TimedDealProvider, CollateralProvider, RefundProvider, BundleProvider } from "../typechain-types"

async function deployAllContracts() {
  // if don't have vaultManager address, can deploy MockVaultManager from mock folder
  const vaultManager = "0x0000000000000000000000000000000000000000" // replace with your vaultManager address
  const baseURI = "https://nft.poolz.finance/test/metadata/"

  // Deploy LockDealNFT contract
  const lockDealNFT: LockDealNFT = await deployed("LockDealNFT", vaultManager, baseURI)
  console.log(`LockDealNFT contract deployed to ${lockDealNFT.address} with vaultManager ${vaultManager}`)

  // Deploy DealProvider contract
  const dealProvider: DealProvider = await deployed("DealProvider", lockDealNFT.address)
  console.log(`DealProvider contract deployed to ${dealProvider.address} with lockDealNFT ${lockDealNFT.address}`)

  // Deploy LockDealProvider contract
  const lockProvider: LockDealProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
  console.log(`LockDealProvider contract deployed to ${lockProvider.address}`)

  // Deploy TimedDealProvider contract
  const timedDealProvider: TimedDealProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
  console.log(`TimedDealProvider contract deployed to ${timedDealProvider.address}`)

  // Deploy CollateralProvider contract
  const collateralProvider: CollateralProvider = await deployed("CollateralProvider", lockDealNFT.address, dealProvider.address)
  console.log(`CollateralProvider contract deployed to ${collateralProvider.address}`)

  // Deploy RefundProvider contract
  const refundProvider: RefundProvider = await deployed("RefundProvider", lockDealNFT.address, collateralProvider.address)
  console.log(`RefundProvider contract deployed to ${refundProvider.address}`)

  // Deploy BundleProvider contract
  const bundleProvider: BundleProvider = await deployed("BundleProvider", lockDealNFT.address)
  console.log(`BundleProvider contract deployed to ${bundleProvider.address}`)
}

deployAllContracts().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
