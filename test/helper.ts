import { ethers } from "hardhat";

export const deployed = async (contractName: string, ...args: any[]): Promise<any> => {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  return contract.deployed();
};