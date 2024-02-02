// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../interfaces/IFeeCollector.sol";
import "../interfaces/ILockDealNFT.sol";
import "../interfaces/IFeeProvider.sol";

contract FeeCollector is IERC721Receiver, IFeeCollector {
    ILockDealNFT public immutable lockDealNFT;
    bool public feeCollected;

    constructor(ILockDealNFT _lockDealNFT) {
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
            (address feeCollector, uint256 fee) = IERC2981(address(lockDealNFT)).royaltyInfo(poolId, amount);
            lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), poolId);
            IERC20 token = IERC20(lockDealNFT.tokenOf(poolId));
            if (fee > 0) token.transfer(feeCollector, fee);
            token.transfer(user, amount - fee);
        }
        if (lockDealNFT.ownerOf(poolId) == address(this)) {
            lockDealNFT.transferFrom(address(this), user, poolId);
        }
        feeCollected = false;
        return IERC721Receiver.onERC721Received.selector;
    }
}
