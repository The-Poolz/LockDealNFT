import { SimpleBuilder } from '../typechain-types';
import { utils } from 'ethers';
import { ethers } from 'hardhat';

export const deployed = async <T>(contractName: string, ...args: string[]): Promise<T> => {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  return contract.deployed() as Promise<T>;
};

export const token = '0xCcf41440a137299CB6af95114cb043Ce4e28679A';
export const BUSD = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';
export const MAX_RATIO = utils.parseUnits('1', 21); // 100%

export async function _createUsers(amount: string, userCount: string): Promise<SimpleBuilder.BuilderStruct> {
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
