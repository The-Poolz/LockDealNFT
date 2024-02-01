// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FeeDealProvider.sol";
import "./FeeLockProvider.sol";
import "./FeeTimedProvider.sol";

contract FeeCollector is IERC721Receiver, IFeeCollector {
    uint256 public fee; // 1e18 = 100%
    address public immutable feeCollector;
    ILockDealNFT public immutable lockDealNFT;
    IProvider public immutable feeDealProvider;
    IProvider public immutable feeLockProvider;
    IProvider public immutable feeTimedProvider;
    bool public feeCollected;

    constructor(uint256 _fee, address _feeCollector, ILockDealNFT _lockDealNFT) {
        fee = _fee;
        feeCollector = _feeCollector;
        lockDealNFT = _lockDealNFT;
        feeDealProvider = new FeeDealProvider(IFeeCollector(this), _lockDealNFT);
        feeLockProvider = new FeeLockProvider(_lockDealNFT, feeDealProvider);
        feeTimedProvider = new FeeTimedProvider(_lockDealNFT, feeLockProvider);
    }

    function onERC721Received(
        address provider,
        address user,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(!feeCollected, "FeeCollectorProvider: fee already collected");
        require(provider == address(lockDealNFT), "FeeCollectorProvider: wrong provider");
        feeCollected = true;
        uint256 amount = lockDealNFT.getWithdrawableAmount(poolId);
        uint256 feeAmount = (amount * fee) / 1e18;
        lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), poolId);
        IERC20 token = IERC20(lockDealNFT.tokenOf(poolId));
        token.transfer(feeCollector, feeAmount);
        token.transfer(user, amount - feeAmount);
        if (lockDealNFT.ownerOf(poolId) == address(this)) {
            lockDealNFT.transferFrom(address(this), user, poolId);
        }
        feeCollected = false;
        return IERC721Receiver.onERC721Received.selector;
    }
}
