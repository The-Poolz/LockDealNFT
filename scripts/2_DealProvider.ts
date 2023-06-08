import { deployed } from "../test/helper";
import { DealProvider } from "../typechain-types/contracts/DealProvider";

async function main() {
  const lockDealNFT = "0xCcf41440a137299CB6af95114cb043Ce4e28679A"// replace with your lockDealNFT address
  const dealProvider: DealProvider = await deployed("DealProvider", lockDealNFT);
  console.log(
    `Contract deployed to ${dealProvider.address} with lockDealNFT ${lockDealNFT}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
