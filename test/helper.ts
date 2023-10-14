import { SimpleBuilder } from '../typechain-types';
import { BuilderState } from '../typechain-types/contracts/Builders/SimpleBuilder/SimpleBuilder';
import { ContractReceipt, utils } from 'ethers';
import { ethers } from 'hardhat';

export const deployed = async <T>(contractName: string, ...args: string[]): Promise<T> => {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args, { gasLimit: gasLimit });
  return contract.deployed() as Promise<T>;
};

export const token = '0xCcf41440a137299CB6af95114cb043Ce4e28679A';
export const BUSD = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';
export const MAX_RATIO = utils.parseUnits('1', 21); // 100%
export const gasLimit: number = 130_000_000;

export function _createUsers(amount: string, userCount: string): BuilderState.BuilderStruct {
  const pools = [];
  const length = parseInt(userCount);
  // Create signers
  for (let i = 0; i < length; ++i) {
    const privateKey = ethers.Wallet.createRandom().privateKey;
    const signer = new ethers.Wallet(privateKey);
    const user = signer.address;
    pools.push({ user: user, amount: amount });
  }
  const totalAmount = ethers.BigNumber.from(amount).mul(length);
  return { userPools: pools, totalAmount: totalAmount };
}

export function _logGasPrice(txReceipt: ContractReceipt, userLength: number) {
  const gasUsed = txReceipt.gasUsed;
  const GREEN_TEXT = '\x1b[32m';
  console.log(`${GREEN_TEXT}Gas Used: ${gasUsed.toString()}`);
  console.log(`Price per one pool: ${gasUsed.div(userLength)}`);
}
