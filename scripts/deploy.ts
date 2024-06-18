import { ethers } from 'hardhat';
import { Contract, ContractFactory } from 'ethers';

async function deployAllContracts() {
  const vaultManager = '0x9ff1db30c66cd9d3311b4b22da49791610922b13'; // replace with your vaultManager address
  const baseURI = 'temp';
  const contractName = 'LockDealNFT';

  try {
    const LockDealNFT = await deploy(contractName, vaultManager, baseURI);
    console.log('LockDealNFT address:', LockDealNFT.address);
  } catch (error) {
    console.error(`Failed to deploy ${contractName}:`, error);
  }
}

const deploy = async <T>(contractName: string, ...args: any[]): Promise<Contract> => {
  try {
    const Contract: ContractFactory = await ethers.getContractFactory(contractName);
    console.log(`Deploying ${contractName}...`);

    const unsignedTx = Contract.getDeployTransaction(...args);
    console.log(`Estimating gas for ${contractName}...`);
    const gasLimit = await ethers.provider.estimateGas(unsignedTx);
    console.log(`Gas limit for ${contractName}: ${gasLimit.toString()}`);

    const gasPrice = await ethers.provider.getGasPrice();
    console.log(`Gas price: ${gasPrice.toString()}`);

    const contract = await Contract.deploy(...args, { gasLimit, gasPrice });
    await contract.deployed();

    console.log(`${contractName} deployed at: ${contract.address}`);
    return contract;
  } catch (error) {
    console.error(`Error deploying ${contractName}:`, error);
    throw error;
  }
};

deployAllContracts().catch(error => {
  console.error('Error in deployAllContracts:', error);
  process.exitCode = 1;
});
