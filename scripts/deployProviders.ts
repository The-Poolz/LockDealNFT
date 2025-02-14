import { DealProvider, LockDealProvider, TimedDealProvider, ERC20Token, LockDealNFT } from '../typechain-types';
import { ethers } from 'hardhat';

async function deployProviders() {
  const lockDealNFT = process.env.LOCK_DEAL_NFT;

  if (!lockDealNFT) {
    throw new Error('lockDealNFT address is not set in the environment variables.');
  }

  // Deploy DealProvider contract
  const dealProviderFactory = await ethers.getContractFactory('DealProvider'); // Get the factory;
  const dealProvider: DealProvider = await dealProviderFactory.deploy(lockDealNFT); // Deploy the contract
  console.log(`DealProvider contract deployed to ${dealProvider.address} with lockDealNFT ${lockDealNFT}`);

  // Deploy LockDealProvider contract
  const lockProviderFactory = await ethers.getContractFactory('LockDealProvider'); // Get the factory;
  const lockProvider: LockDealProvider = await lockProviderFactory.deploy(lockDealNFT, dealProvider.address); // Deploy the contract
  console.log(`LockDealProvider contract deployed to ${lockProvider.address}`);

  // Deploy TimedDealProvider contract
  const timedDealProviderFactory = await ethers.getContractFactory('TimedDealProvider'); // Get the factory;
  const timedDealProvider: TimedDealProvider = await timedDealProviderFactory.deploy(lockDealNFT, lockProvider.address); // Deploy the contract
  console.log(`TimedDealProvider contract deployed to ${timedDealProvider.address}`);
}

deployProviders().catch(error => {
  console.error(error);
  process.exitCode = 1;
});