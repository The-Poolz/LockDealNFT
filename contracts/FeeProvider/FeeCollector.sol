// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../interfaces/IFeeCollector.sol";
import "../interfaces/ILockDealNFT.sol";
import "../interfaces/IFeeProvider.sol";

contract FeeCollector is IERC721Receiver, IFeeCollector {
    uint256 public fee; // 1e18 = 100%
    address public immutable feeCollector;
    ILockDealNFT public immutable lockDealNFT;
    bool public feeCollected;

    constructor(uint256 _fee, address _feeCollector, ILockDealNFT _lockDealNFT) {
        fee = _fee;
        feeCollector = _feeCollector;
        lockDealNFT = _lockDealNFT;
    }

    function onERC721Received(
        address,
        address user,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == address(lockDealNFT), "FeeCollector: invalid nft contract");
        require(!feeCollected, "FeeCollector: fee already collected");
        IProvider feeProvider = lockDealNFT.poolIdToProvider(poolId);
        require(
            ERC165Checker.supportsInterface(address(feeProvider), type(IFeeProvider).interfaceId),
            "FeeCollector: wrong provider"
        );
        feeCollected = true;
        uint256 amount = lockDealNFT.getWithdrawableAmount(poolId);
        if (amount > 0) {
            uint256 feeAmount = (amount * fee) / 1e18;
            lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), poolId);
            IERC20 token = IERC20(lockDealNFT.tokenOf(poolId));
            if (feeAmount > 0) token.transfer(feeCollector, feeAmount);
            token.transfer(user, amount - feeAmount);
        }
        if (lockDealNFT.ownerOf(poolId) == address(this)) {
            lockDealNFT.transferFrom(address(this), user, poolId);
        }
        feeCollected = false;
        return IERC721Receiver.onERC721Received.selector;
    }
}
