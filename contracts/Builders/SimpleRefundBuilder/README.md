# SimpleRefundBuilder

`The SimpleRefundBuilder` is a **Solidity** smart contract designed for the efficient mass creation of [Refund provider](https://github.com/The-Poolz/LockDealNFT/tree/master/contracts/AdvancedProviders/RefundProvider) **Non-Fungible Tokens (NFTs).** Its primary purpose is to streamline the process of creating multiple refund pools. By leveraging the capabilities of this contract, users can initiate the creation of **RefundProvider NFTs** in a single transaction, simplifying the management of refundable deals.

**BSC Testnet** contract address [link](https://testnet.bscscan.com/address/0x9c39a03459522185a1598d4ad2a9ccccb0f5ff8f).

### Building Mass Refund Pools

```solidity
function buildMassPools(
        address[] calldata addressParams,
        Builder calldata userData,
        uint256[][] calldata params,
        bytes calldata tokenSignature,
        bytes calldata mainCoinSignature
    ) public
```

**The buildMassPools** function is a core feature of the `SimpleRefundBuilder` contract, offering a convenient and efficient mechanism for the mass creation of `Refund provider` **Non-Fungible Tokens (NFTs)**. This function enables users to initiate the creation of multiple refund pools in a single transaction.

**BSC Testnet** transaction example [link](https://testnet.bscscan.com/tx/0xc997126c7f59d7750e07447de84b612fe40c81e5390281d35f51a20ada1f72bf)

#### Parameters:

```solidity
// An array containing three addresses:
// addressParams[0]: simpleProvider: The address of the simple provider contract responsible for managing refund pools.
// addressParams[1]: token: The address of the ERC-20 token used in the refund pools.
// addressParams[2]: mainCoin: The address of the main coin used in collateralized deals.
address[] calldata addressParams;
```

```solidity
// A data structure containing user-related information for the mass creation of refund pools.
// Builder.userPools: An array of UserPool structures, where each structure contains:
// Builder.userPools.user: The address of the user participating in the refund pool.
// Builder.userPools.amount: The amount of tokens allocated to the user's pool.
// totalAmount: The total amount of tokens involved in the mass pool creation.
Builder calldata userData;
```

```solidity
// A 2D array containing parameters for the mass pool creation process:
// params[0]: Collateral parameters, including the starting amount and finish time.
// params[1]: Array of parameters for the simple provider. This array may be empty if the provider is a DealProvider.
uint256[][] calldata params;
```

```solidity
// The cryptographic signature associated with token-related operations, providing a secure means of token transfer.
bytes calldata tokenSignature;
```

```solidity
// The cryptographic signature associated with main coin-related operations in collateralized deals,
// ensuring the integrity of main coin transfers.
bytes calldata mainCoinSignature;
```

### Contract structure

![classDiagram](https://github.com/The-Poolz/LockDealNFT/assets/68740472/c0b55b93-689d-48e0-a717-3f0d3fd65545)

### Collateral Provider

After creating mass refund pools, `msg.sender` assumes the role of the **Project owner**. The **Project owner** possesses an NFT from the `Collateral Provider`, allowing interaction for governance purposes

## License

[The-Poolz](https://poolz.finance/) Contracts is released under the [MIT License](https://github.com/The-Poolz/DelayVaultProvider/blob/master/LICENSE).
