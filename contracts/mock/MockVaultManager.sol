// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockVaultManager {
    mapping(address => uint) public tokenToVaultId;
    mapping(uint256 => address) vaultIdtoToken;
    uint256 public Id = 0;

    function depositByToken(address _tokenAddress, address, uint) external returns (uint vaultId) {
        vaultId = ++Id;
        vaultIdtoToken[vaultId] = _tokenAddress;
        tokenToVaultId[_tokenAddress] = vaultId;
    }

    function withdrawByVaultId(uint _vaultId, address to, uint _amount) external {
        // do nothing
    }

    function vaultIdToTokenAddress(uint _vaultId) external view returns (address) {
        return vaultIdtoToken[_vaultId];
    }

    function royaltyInfo(uint256, uint256) external pure returns (address receiver, uint256 royaltyAmount) {
        return (address(0), 0);
    }

    function vaultIdToTradeStartTime(uint256) external view returns (uint256) {
        return block.timestamp - 1;
    }
}
