# CollateralProvider
**CollateralProvider** is a contract that enables the management of `tokens` and `main coins` for the **Project Owner**. 

## Pools
When registering a pool, three types of pools are created for refund purposes.

#### Main Coin Pool
If a user withdraws their tokens before the end of the lock-up period, a portion of the main coins, based on the withdrawal amount and the defined rate, becomes accessible to the project owner. The main coin pool holds this portion and allows the withdrawal of main coins before the time limit expires.

#### Token Pool
In the event that some users initiate a refund, the tokens they exchange for main coins are sent to the token pool. The project owner has access to withdraw tokens from this pool before the finish time limit.

#### Refund Main Coin Pool
This pool holds an initial amount of main coins to facilitate the refund process. Users who wish to request a refund exchange their tokens for main coins, resulting in a decrease in the amount held in the Refund Main Coin pool and an increase in the Token pool. After the time limit, the project owner gains access to the Refund Main Coin pool.

**Сollateral provider** interacts with other providers to correctly calculate the required accrual amounts for **Collector** pools.

## Rate To Wei
The `poolIdToRateToWei` variable is a mapping within the **CollateralProvider** contract that associates each pool ID with a rate conversion factor from main coins to tokens. This mapping is crucial for calculating the exchange rate between the main coin (e.g., USDT) and the corresponding tokens within each pool.
```solidity
mapping(uint256 => uint256) public poolIdToRateToWei;
```
* Key (uint256): Represents the unique identifier of a collateral pool (poolId).
* Value (uint256): Represents the rate conversion factor from main coins to tokens associated with the specified pool.
### Example Usage

```
// Example values
// Updated example values in Wei
uint256 mainCoinAmount = 300 * 10**18;  // Main coin amount, e.g., USDT in Wei
uint256 tokenAmount = 150 * 10**18;     // Token amount in Wei

// Calculate exchange rate
uint256 rate = (mainCoinAmount * 1e21) / tokenAmount;

// Output the result
// rate = (300 * 1e21) / 150 = 2e18
```
In this case, the values for `mainCoinAmount` and `tokenAmount` are represented in `Wei` (the smallest unit of ether). The resulting rate is `2*10**18` or `2e18`. The resulting rate indicates that for every `1 Wei` of the tokens, a user would receive `2e18 Wei` worth of main coins based on this exchange rate.


### Conclusion

* The **CollateralProvider** contract provides a comprehensive solution for managing tokens and main coins for the Project Owner. With its time-limited collateral pools, it ensures that funds are securely held until a specific time limit is reached. Once the time limit expires, the Project Owner gains full control over the Collector pools, enabling efficient fund withdrawal.

* Contract creates three types of pools: the **Main Coin Pool**, **Token Pool**, and **Refund Main Coin Pool**. These pools facilitate the exchange and withdrawal of tokens and main coins based on user actions and the defined time limit. Users withdrawing tokens increase the **Main Coin pool** and decrease the **Refund Main coin pool**, while those who initiate a refund exchange tokens for main coins, which affects the **Token pool** and the **Refund Main coin pool**.

* The **CollateralProvider** contract collaborates with other providers to accurately calculate the required accrual amounts for the Collector pools, ensuring transparency and reliability in fund management.

## License
The **CollateralProvider** contract is released under the MIT License.