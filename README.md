# LockDealNFT

[![Build and Test](https://github.com/The-Poolz/LockDealNFT/actions/workflows/node.js.yml/badge.svg)](https://github.com/The-Poolz/LockDealNFT/actions/workflows/node.js.yml)
[![codecov](https://codecov.io/gh/The-Poolz/LockDealNFT/branch/master/graph/badge.svg?token=s2B22Bif9x)](https://codecov.io/gh/The-Poolz/LockDealNFT)
[![CodeFactor](https://www.codefactor.io/repository/github/the-poolz/lockdealnft/badge)](https://www.codefactor.io/repository/github/the-poolz/lockdealnft)
[![npm version](https://img.shields.io/npm/v/@poolzfinance/lockdeal-nft/latest.svg)](https://www.npmjs.com/package/@poolzfinance/lockdeal-nft/v/latest)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/The-Poolz/LockDealNFT/blob/master/LICENSE)

Basic data:
![Providers-table](https://github.com/The-Poolz/LockDealNFT/assets/68740472/bb72b0e9-67da-4658-bb14-07f1997d326d)


### Audit Report
The audit report is available here: [Audit Report](https://docs.google.com/document/d/18XSwsKKbHpLCr4MQNZe8nZSWHnG6aExtb57R5uzQ3Us/edit?tab=t.0#heading=h.5uoc4mfz7mn4)

### Pool Creation:

To create a new pool, users should leverage a **Provider** contract, which acts as a gateway for creating pools. The process begins with the creator sending a designated number of tokens to the **Vault** associated with the `Pool`. The **Providers** and **LockDealNFT** then store the pool data. Each `Provider` has its own number of pool parameters like `amount`, `time`, etc. Part of the data, such as the `token` and the `owner`, is stored in the **LockDealNFT** contract, the rest of the data is stored in the **Provider** itself.

### Role of Providers:

- **Providers** serve as data repositories for the pools within the system. They store important information and ensure its accessibility whenever required. However, providers do not directly handle token storage; they delegate this responsibility to **Vaults**. By separating data storage from token storage, providers streamline operations and enhance system efficiency.
- **Providers** employ cascading logic to minimize the duplication of code across multiple contracts. They encapsulate commonly used functions, algorithms, and business rules, making them accessible to different contracts within the system. This approach eliminates redundancy, simplifies code maintenance, and promotes cleaner code architecture.

- **Providers** are also used by the Locked Deal NFT contract to manage splits and withdrawals.

### Minting of NFTs:

When a new pool is created, the system automatically mints a non-fungible token (NFT) by using the **LockDealNFT** contract. This NFT acts as a unique identifier and proof of ownership for the pool. It establishes an immutable record that verifies the creator's ownership rights over the pool. This mechanism ensures transparency and security in pool ownership transactions.

### LockDealNFT and Pool Management:

**LockDealNFT** enable the splitting and withdrawal of pools using **Providers** and the **VaultManager**. Pool splitting allows users to split a pool into smaller units, facilitating various investment strategies and accommodating diverse liquidity needs. Withdrawal, on the other hand, permits users to retrieve their assets from the pool when necessary. **Providers** and the **VaultManager** work in tandem to ensure the smooth execution of these operations, providing users with greater control over their investments.

### API

the API can be found here: [LockDeal-NFT-API](https://github.com/The-Poolz/LockDeal-NFT-API)

### Conclusion:

Providers play a pivotal role in the creation and management of pools within our system. They store pool data and delegate token storage to vaults. Additionally, the creation of NFTs establishes proof of ownership for the pools. LockDealNFTs further enhance pool management by enabling pool splitting and withdrawal. By leveraging providers and the vaultManager, users can efficiently manage their assets, tailor investment strategies, and enjoy increased liquidity options within the system.

## License

[The-Poolz](https://poolz.finance/) Contracts is released under the [MIT License](https://github.com/The-Poolz/LockDealNFT/blob/master/LICENSE).
