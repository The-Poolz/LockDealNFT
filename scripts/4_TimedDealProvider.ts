import { deployed } from "../test/helper";
import { TimedDealProvider } from "../typechain-types/contracts/TimedDealProvider/TimedDealProvider";

async function main() {
  const lockDealNFT = "0xCcf41440a137299CB6af95114cb043Ce4e28679A"// TODO: replace with your lockDealNFT address
  const lockProvider = "0x520bf33F8426F32ec23B625133C961c96605da5e"// TODO: replace with your lockProvider address
  let timedDealProvider: TimedDealProvider = await deployed("TimedDealProvider", lockDealNFT, lockProvider);
  console.log(
    `Contract deployed to ${timedDealProvider.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
