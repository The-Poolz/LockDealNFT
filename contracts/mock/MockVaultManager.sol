// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

contract MockVaultManager is SphereXProtected {
    mapping(address => uint) public tokenToVaultId;
    mapping(uint256 => address) vaultIdtoToken;
    bool public transfers = true;
    uint256 public Id = 0;

    function setTransferStatus(bool status) external sphereXGuardExternal(0xaac52c47) {
        transfers = status;
    }

    function safeDeposit(address _tokenAddress, uint, address, bytes memory signature) external sphereXGuardExternal(0xc4f653f0) returns (uint vaultId) {
        require(keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked("signature")), "wrong signature");
        vaultId = _depositByToken(_tokenAddress);
    }

    function depositByToken(address _tokenAddress, uint256 amount) public sphereXGuardPublic(0xbf98b25c, 0x5a131fb0) returns (uint vaultId) {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        vaultId = _depositByToken(_tokenAddress);
    }

    function _depositByToken(address _tokenAddress) internal sphereXGuardInternal(0x76721734) returns (uint vaultId) {
        vaultId = ++Id;
        vaultIdtoToken[vaultId] = _tokenAddress;
        tokenToVaultId[_tokenAddress] = vaultId;
    }

    function withdrawByVaultId(uint _vaultId, address to, uint _amount) external sphereXGuardExternal(0xac076c8e) {
        // do nothing
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
