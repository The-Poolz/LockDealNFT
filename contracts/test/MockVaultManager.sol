// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockVaultManager {
    address public tokenAddress;

    function depositByToken(
        address _tokenAddress,
        address from,
        uint _amount
    ) external returns (uint vaultId) {
        tokenAddress = _tokenAddress;
        IERC20(_tokenAddress).transferFrom(from, address(this), _amount);
        vaultId = 0;
    }

    function withdrawByVaultId(
        uint /** _vaultId **/,
        address to,
        uint _amount
    ) external {
        IERC20(tokenAddress).transfer(to, _amount);
    }
}
