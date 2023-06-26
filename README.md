# LockDealNFT

[![Build and Test](https://github.com/The-Poolz/LockDealNFT/actions/workflows/node.js.yml/badge.svg)](https://github.com/The-Poolz/LockDealNFT/actions/workflows/node.js.yml)
[![codecov](https://codecov.io/gh/The-Poolz/LockDealNFT/branch/master/graph/badge.svg?token=s2B22Bif9x)](https://codecov.io/gh/The-Poolz/LockDealNFT)
[![CodeFactor](https://www.codefactor.io/repository/github/the-poolz/lockdealnft/badge)](https://www.codefactor.io/repository/github/the-poolz/lockdealnft)


Basic data:
![image](https://github.com/The-Poolz/LockDealNFT/assets/48094744/7616eb4e-970b-4984-9da9-350e4d6f05dc)

### Pool Creation:
To create a new pool, users should leverage a **Provider** contract, which acts as a gateway for the creation of pools. The process begins with the creator sending a designated number of tokens to the **Vault** associated with the `Pool`. The **Providers** and **LockDealNFT** then store the pool data. Each `Provider` has its own number of pool parameters like `amout`, `time`, etc. Part of the data, such as the `token` and the `owner`, is stored in the **LockDealNFT** contract, the rest of the data is stored in the **Provider** itself.

### Role of Providers:
* **Providers** serve as data repositories for the pools within the system. They store important information and ensure its accessibility whenever required. However, providers do not directly handle token storage; instead, they delegate this responsibility to **Vaults**. By separating data storage from token storage, providers streamline operations and enhance system efficiency.
  
 * **Providers** employ cascading logic to minimize the duplication of code across multiple contracts. They encapsulate commonly used functions, algorithms, and business rules, making them accessible to different contracts within the system. This approach eliminates redundancy, simplifies code maintenance, and promotes cleaner code architecture.
  
 * **Providers** are also used by the Locked Deal NFT contract to manage splits and withdrawals.

### Minting of NFTs:
When a new pool is created, the system automatically mints a non-fungible token (NFT) by using **LockDealNFT** contract. This NFT acts as a unique identifier and proof of ownership for the pool. It establishes an immutable record that verifies the creator's ownership rights over the pool. This mechanism ensures transparency and security in pool ownership transactions.

### LockDealNFT and Pool Management:
**LockDealNFT** enable the splitting and withdrawal of pools using **Providers** and the **VaultManager**. Pool splitting allows users to split a pool into smaller units, facilitating various investment strategies and accommodating diverse liquidity needs. Withdrawal, on the other hand, permits users to retrieve their assets from the pool when necessary. **Providers** and the **VaultManager** work in tandem to ensure the smooth execution of these operations, providing users with greater control over their investments.

### Conclusion:
Providers play a pivotal role in the creation and management of pools within our system. They store pool data and delegate token storage to vaults. Additionally, the creation of NFTs establishes proof of ownership for the pools. LockDealNFTs further enhance pool management by enabling pool splitting and withdrawal. By leveraging providers and the vaultManager, users can efficiently manage their assets, tailor investment strategies, and enjoy increased liquidity options within the system.
