# DealProvider
The **DealProvider** smart contract assumes a pivotal role within a decentralized application ecosystem tailored to optimize the storage of left amounts for `NFT pools`. Collaborating harmoniously with the **LockDealNFT** contract, which serves as the core of this system, the **DealProvider** assumes the pivotal responsibility of accurately tallying tokens across diverse pools.

### Navigation

- [Introduction](#introduction)
- [Contract Overview](#contract-overview)
- [Functionality](#functionality)
- [Integration with LockDealNFT](#integration-with-lockdealnft)
- [Responsibilities](#responsibilities)
- [License](#license)

## Introduction

The **DealProvider** contract is a smart contract aiming to manage and facilitate the splitting and withdrawal of tokens within the context of a deal ecosystem. It cooperates closely with the **LockDealNFT** contract and complements its functionalities by handling token-related operations that are not performed directly through the **LockDealNFT** contract.

## Contract Overview
The contract consists of several core components:

* **Inheritance:** The **DealProvider** contract inherits from two parent contracts: **DealProviderState** and **BasicProvider**. These parent contracts provide state storage and fundamental functions that the **DealProvider** utilizes.

* **Constructor:** The contract's constructor initializes the contract by requiring an instance of the **ILockDealNFT** interface (_nftContract). This interface represents the **LockDealNFT** contract address, ensuring a connection between the two contracts.

* **Withdrawal Logic:** The `_withdraw` function is an internal function responsible for processing withdrawal requests. It allows for the withdrawal of a specified amount of tokens from a designated pool, and it ensures that the withdrawal is feasible and in accordance with the remaining available amount.

* **Split Functionality:** The `split` function allows for the division of a pool into two new pools based on a specified ratio. This feature provides flexibility for managing token distribution within the ecosystem.

* **Pool Registration:** The `_registerPool` function is internally used for registering a new pool with its initial token amount. It receives a pool ID and an array of parameters, and it updates the state accordingly.

* **View Functions:** The contract includes several view functions that facilitate querying relevant data, such as the parameters of a pool (`getParams`) and the amount of tokens available for withdrawal (`getWithdrawableAmount`).

## Functionality
**The DealProvider** contract primarily focuses on three key functionalities:

* **Withdrawal Management:** It enables users to withdraw tokens from a designated pool while ensuring that the withdrawal does not exceed the available amount.

* **Splitting Pools:** The contract allows for the division of a pool into two separate pools based on a provided ratio. This feature can be used to reorganize token distribution as needed.

* **Pool Registration:** The contract provides a mechanism for registering new pools, initializing them with an initial token amount. This functionality assists in keeping track of various pools within the ecosystem.

## Integration with LockDealNFT
**The DealProvider** contract collaborates closely with the **LockDealNFT** contract. While the **LockDealNFT** contract handles the issuance of `NFTs` and represents deal ownership, the **DealProvider** takes on the role of managing token-related operations. This symbiotic relationship ensures a streamlined process for token `splitting`, `withdrawal`, and `pool management` within the larger deal ecosystem.

## Responsibilities
**The DealProvider** contract assumes the following responsibilities:

* Managing token withdrawal and ensuring compliance with available amounts.
* Facilitating the division of pools to manage token distribution.
* Registering and tracking pools within the ecosystem.
* Collaborating with the **LockDealNFT** and other **Providers** contracts for comprehensive deal management.

## License
The-Poolz Contracts is released under the MIT License.