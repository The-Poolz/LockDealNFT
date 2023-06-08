import { deployed } from "../test/helper";
import { LockDealProvider } from "../typechain-types/contracts/LockProvider/LockDealProvider";

async function main() {
  const lockDealNFT = "0xCcf41440a137299CB6af95114cb043Ce4e28679A"// replace with your lockDealNFT address
  const dealProvider = "0x5cA05dB2c7377DdB964097B139A7958f0723A70b"// replace with your dealProvider address
  const lockProvider: LockDealProvider = await deployed("LockDealProvider", lockDealNFT, dealProvider);
  console.log(
    `Contract deployed to ${lockProvider.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
