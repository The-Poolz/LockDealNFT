// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockVaultManager {
    mapping(address => uint) public tokenToVaultId;
    mapping(uint256 => address) vaultIdtoToken;
    bool public transfers = false;
    uint256 public Id = 0;

    function setTransferStatus(bool status) external {
        transfers = status;
    }

    function safeDeposit(
        address _tokenAddress,
        uint amount,
        address from,
        bytes memory signature
    ) external returns (uint vaultId) {
        require(keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked("signature")), "wrong signature");
        vaultId = _depositByToken(_tokenAddress, from, amount);
    }

    function depositByToken(address _tokenAddress, uint256 amount) public returns (uint vaultId) {
        vaultId = _depositByToken(_tokenAddress, msg.sender, amount);
    }

    function _depositByToken(address _tokenAddress, address from, uint256 amount) internal returns (uint vaultId) {
        vaultId = ++Id;
        vaultIdtoToken[vaultId] = _tokenAddress;
        tokenToVaultId[_tokenAddress] = vaultId;
        if (transfers) IERC20(_tokenAddress).transferFrom(from, address(this), amount);
    }

    function withdrawByVaultId(uint _vaultId, address to, uint _amount) external {
        if (_amount > 0 && transfers) IERC20(vaultIdtoToken[_vaultId]).transfer(to, _amount);
    }

    function vaultIdToTokenAddress(uint _vaultId) external view returns (address) {
        return vaultIdtoToken[_vaultId];
    }

    function royaltyInfo(uint256, uint256) external pure returns (address receiver, uint256 royaltyAmount) {
        return (address(0), 0);
    }

    function vaultIdToTradeStartTime(uint256) external view returns (uint256) {
        return transfers ? block.timestamp - 1 : block.timestamp + 1;
    }
}
