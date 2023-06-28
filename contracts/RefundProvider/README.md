# RefundProvider
**RefundProvider** introduces a comprehensive contract that implement the **[Risk Free](https://blog.poolz.finance/poolz-risk-free-ido-model/)** and **[Secured](https://blog.poolz.finance/introducing-the-poolz-secured-ido-model/)** models. The `RefundProvider` smart contract is designed to enable flexible interactions with providers of various parameter lengths. The contract is abstracted from the specific provider it works with and can seamlessly integrate with `DealProvider`, `LockProvider`, and `TimedProvider` to perform all its functionalities.

## User
`User` interacting with the **RefundProvider** contract have the following rights and capabilities:

* **Split:** have the right to divide owned pools into separate entities. This functionality enables to split tokens into multiple pools, each with a distinct number of tokens. When the split occurs, the corresponding Main Coin pools are also separated, and they are specifically designated for use in refund processes.

* **Withdrawal:** can withdraw tokens from its own pools. This action allows users to withdraw a portion of their tokens from a specific pool, depending on the provider's settings.

* **Refund:** also have the option to initiate a refund process for tokens locked in pools. When a refund is initiated, a predetermined number of Main Coins are exchanged for the Locked Tokens In this process, the user receives the Main Coins in exchange for tokens, effectively transferring ownership of the tokens to the refund provider. 

Users are granted a specific window of time during which they can swap their tokens for Main Coins at a predefined ratio. This feature enables users to exchange their tokens for the primary currency within the designated time frame

## Project Owner
The `Project Owner` refers to the original creator of the RefundProvider pools. The Project Owner assumes the following roles and responsibilities:

* **Refund Process Limit:** The Project Owner has the authority to set a time limit for the availability of the refund process. Once this period expires, the swapping of tokens for Main Coins will no longer be possible, and the Project Owner can reclaim the locked Main Coins.

* **Main Coin Pool:** If a user has withdrawn a portion of their tokens, a pool containing a certain ratio of Main Coins is created specifically for the Project Owner. This pool remains accessible to the Project Owner without any time limitations. 

* **Ownership of Tokens after refund:** In cases where a user initiates a refund and exchanges their tokens for Main Coins, the ownership of the tokens is transferred to the Project Owner. Consequently, the Project Owner becomes the rightful owner of the tokens exchanged during the refund process.