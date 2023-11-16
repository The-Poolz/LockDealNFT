# SimpleBuilder

`SimpleBuilder` is a **Solidity** smart contract designed for the mass creation of [Simple Provider](https://github.com/The-Poolz/LockDealNFT/tree/master/contracts/SimpleProviders) **NFTs**.

**BSC Testnet** contract address [link](https://testnet.bscscan.com/address/0x4338c2706052930c065cd7fe396f4e70494cf7b3).

### Building Mass Pools

```solidity
function buildMassPools(
        address[] calldata addressParams,
        Builder calldata userData,
        uint256[] calldata params,
        bytes calldata signature
    ) external
```

The **buildMassPools** function is a crucial part of the `SimpleBuilder` smart contract, responsible for creating multiple lock deals **(NFTs)** in a batch or mass pool. This function is designed to be externally callable, allowing users to efficiently create a set of **NFTs** in a single transaction.

#### Parameters:

```solidity
// An array containing two addresses:
// addressParams[0]: Provider address.
// addressParams[1]: Token address.
address[] calldata addressParams;
```

```solidity
// An instance of the Builder struct, containing user pool data:
// userData.userPools: An array of UserPool structs, each specifying the user and the corresponding amount.
// userData.totalAmount: The total amount to be distributed among the user pools.
Builder calldata userData;
```

```solidity
// An array of additional parameters based on the `Simple Provider` requirements.
uint256[] calldata params;
```

```solidity
// Signature to verify the validity of `sender` authentication.
bytes calldata signature;
```

### Contract sturcture

![classDiagram](https://github.com/The-Poolz/LockDealNFT/assets/68740472/6576e9b0-7c47-489d-bf80-2eeb42417832)

## License

[The-Poolz](https://poolz.finance/) Contracts is released under the [MIT License](https://github.com/The-Poolz/DelayVaultProvider/blob/master/LICENSE).
