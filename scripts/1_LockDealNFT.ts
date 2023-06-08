import { deployed } from "../test/helper";
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT";

async function main() {
  const vaultManager = "0x240e127c67904984f8F42e49084e2Cc1b875D47D"// replace with your vaultManager address
  const lockDealNFT: LockDealNFT = await deployed("LockDealNFT", vaultManager);
  console.log(
    `Contract deployed to ${lockDealNFT.address} with vaultManager ${vaultManager}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
