import { deployed } from '../test/helper';
import { LockDealNFT, DealProvider, LockDealProvider, TimedDealProvider } from '../typechain-types';
import { ethers } from 'hardhat';

async function deployAllContracts() {
  const vaultManager = process.env.VAULT_MANAGER;
  const baseURI = process.env.BASE_URI;

  if (!vaultManager || !baseURI) {
    throw new Error('vaultManager or baseURI address is not set in the environment variables.');
  }

  // Deploy LockDealNFT contract
  const LockDealNFTFactory = await ethers.getContractFactory('LockDealNFT');
  const lockDealNFT: LockDealNFT = await LockDealNFTFactory.deploy(vaultManager, baseURI);
  console.log(`LockDealNFT contract deployed to ${lockDealNFT.address} with vaultManager ${vaultManager}`);

  // Deploy DealProvider contract
  const dealProviderFactory = await ethers.getContractFactory('DealProvider');
  const dealProvider: DealProvider = await dealProviderFactory.deploy(lockDealNFT.address);
  console.log(`DealProvider contract deployed to ${dealProvider.address} with lockDealNFT ${lockDealNFT.address}`);

  // Deploy LockDealProvider contract
  const LockDealProviderFactory = await ethers.getContractFactory('LockDealProvider');
  const lockProvider: LockDealProvider = await LockDealProviderFactory.deploy(
    lockDealNFT.address,
    dealProvider.address,
  );
  console.log(`LockDealProvider contract deployed to ${lockProvider.address}`);

  // Deploy TimedDealProvider contract
  const timedDealProvider: TimedDealProvider = await deployed(
    'TimedDealProvider',
    lockDealNFT.address,
    lockProvider.address,
  );
  console.log(`TimedDealProvider contract deployed to ${timedDealProvider.address}`);
}

deployAllContracts().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
