import { SimpleBuilder } from '../../typechain-types';
import { ethers } from 'hardhat';

// helper functions
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