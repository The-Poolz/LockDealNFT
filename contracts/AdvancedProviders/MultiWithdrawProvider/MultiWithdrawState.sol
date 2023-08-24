// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MultiWithdrawState is Ownable{
    ///@dev Each provider sets its own name
    string public name;
    ILockDealNFT public lockDealNFT;

    uint256 public maxPoolsPerTx;

    modifier onlyAdminOrNftOwner(address _nftOwner) {
        require(msg.sender == owner() || msg.sender == _nftOwner, "Only admin or nft owner");
        _;
    }

    modifier onlyNFT() {
        _onlyNFT();
        _;
    }

    function setMaxPoolsPerTx(uint256 _maxPoolsPerTx) external onlyOwner {
        maxPoolsPerTx = _maxPoolsPerTx;
    }

    function _onlyNFT() internal view {
        require(msg.sender == address(lockDealNFT), "only NFT contract can call this function");
    }
}