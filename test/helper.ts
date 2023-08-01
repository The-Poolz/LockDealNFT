import { ethers } from "hardhat";

export const deployed = async <T>(contractName: string, ...args: string[]): Promise<T> => {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  return contract.deployed() as Promise<T>;
};

export const token = "0xCcf41440a137299CB6af95114cb043Ce4e28679A"
export const BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"