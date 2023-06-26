// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTState.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract LockDealNFTModifiers is LockDealNFTState, Ownable {
    modifier onlyApprovedProvider() {
        _onlyApprovedProvider(msg.sender);
        _;
    }

    modifier onlyOwnerOrAdmin(uint256 poolId) {
        _onlyOwnerOrAdmin(poolId);
        _;
    }

    modifier onlyContract(address contractAddress) {
        _onlyContract(contractAddress);
        _;
    }

    modifier notZeroAddress(address _address) {
        _notZeroAddress(_address);
        _;
    }

    modifier notZeroAmount(uint256 amount) {
        _notZeroAmount(amount);
        _;
    }

    modifier approvedAmount(address token, address from, uint256 amount) {
        _approvedAmount(token, from, amount);
        _;
    }

    modifier validPoolId(uint256 poolId){
        _validPoolId(poolId);
        _;
    }

    function _notZeroAddress(address _address) private pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }

    function _onlyContract(address contractAddress) private view {
        require(
            Address.isContract(contractAddress),
            "Invalid contract address"
        );
    }

    function _onlyOwnerOrAdmin(uint256 poolId) internal view {
        require(
            msg.sender == ownerOf(poolId) || msg.sender == owner(),
            "invalid caller address"
        );
    }

    function _onlyApprovedProvider(address provider) internal view {
        require(approvedProviders[provider], "Provider not approved");
    }

    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount should be greater than 0");
    }

    function _approvedAmount(address token, address from, uint256 amount) internal view {
        require(
            IERC20(token).allowance(from, address(vaultManager)) >= amount,
            "Sending tokens not approved"
        );
    }

    function _validPoolId(uint256 poolId) internal view {
        require(_exists(poolId), "Pool does not exist");
    }
}
