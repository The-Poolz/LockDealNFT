// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "../ProviderInterface/IProviderSingleIdRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract RefundProvider is RefundState, IERC721Receiver {
    constructor(address nftContract, address provider) {
        require(nftContract != address(0x0) && provider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(nftContract);
        lockProvider = LockDealProvider(provider);
    }

    ///@dev refund implementation
    function onERC721Received(
        address,
        address from,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        if (lockDealNFT.poolIdToProvider(poolId) == address(this)) {
            require(lockProvider.startTimes(poolId - 1) > block.timestamp, "too late");
            DealProvider dealProvider = lockProvider.dealProvider();
            lockDealNFT.setPoolIdToProvider(address(dealProvider), poolId - 2);
            lockDealNFT.safeTransferFrom(address(this), lockDealNFT.ownerOf(poolId - 1), poolId - 2); // add approve on create

            lockDealNFT.setPoolIdToProvider(address(dealProvider), poolId - 1);
            lockDealNFT.safeTransferFrom(lockDealNFT.ownerOf(poolId - 1), from, poolId - 1); // add approve on create
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    ///@param params[0] = tokenLeftAmount
    ///@param params[params.length - 2] = refundMainCoinAmount
    ///@param params[params.length - 1] = refund finish time
    function createNewRefundPool(
        address token,
        address owner,
        address mainCoin,
        address provider,
        uint256[] calldata params
    ) external returns (uint256 poolId) {
        uint256 paramsLength = params.length;
        require(paramsLength > 2, "invalid params length");

        /// Hold token (data) | Owner Refund
        uint256 dataPoolID = lockDealNFT.mint(address(this), token, msg.sender, 0, provider);
        IProviderSingleIdRegistrar(provider).registerPool(dataPoolID, address(this), token, params);

        /// Hold main coin | Owner Refund
        uint256 [] memory mainCoinParams = new uint256[](2);
        mainCoinParams[0] = params[paramsLength - 2];
        mainCoinParams[1] = params[paramsLength - 1];
        uint256 lockProviderPoolId = lockDealNFT.mint(msg.sender, mainCoin, msg.sender, mainCoinParams[0], address(lockProvider));
        lockProvider.registerPool(lockProviderPoolId, address(this), mainCoin, mainCoinParams);

        /// real owner poolId
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0], address(this));
    }

    ///@dev the user splits his tokens into main coins
    function split(
        uint256 poolId,
        uint256 newPoolId, // new pool id for the data Holder token
        uint256 splitAmount
    ) external onlyNFT {
        // split tokens amount
        address provider = lockDealNFT.poolIdToProvider(poolId - 2);
        DealProvider dealProvider = lockProvider.dealProvider();

        (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256 [] memory params) = IProvider(provider).getData(poolId - 2);
        IProvider(provider).split(poolId - 2, newPoolId, splitAmount);

        (address mainCoin, uint256 mainCoinAmount) = dealProvider.poolIdToDeal(poolId - 1);
        uint256 mainCoinSplitAmount = _calcAmount(splitAmount, _calcRate(params[0], mainCoinAmount));
        address projectOwner = lockDealNFT.ownerOf(poolId - 1);
        uint256 lockProviderPoolId = lockDealNFT.mint(projectOwner, mainCoin, msg.sender, 0, address(lockProvider));
        IProvider(provider).split(poolId - 1, lockProviderPoolId, mainCoinSplitAmount);

        lockDealNFT.mint(poolInfo.owner, poolInfo.token, msg.sender, 0, address(this));
    }

    function _calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return tokenBValue != 0 ? (tokenAValue * 1e18) / tokenBValue : 0;
    }

    function _calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return rate != 0 ? (amount * 1e18) / rate : 0;
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        // user withdraws his token from the provider by cascading providers params
        DealProvider dealProvider = lockProvider.dealProvider();
        (, uint256 tokenAmount) = dealProvider.poolIdToDeal(poolId - 2);
        (withdrawnAmount, isFinal) = lockDealNFT.withdraw(poolId - 2);

        if (withdrawnAmount > 0 && lockProvider.startTimes(poolId - 1) <= block.timestamp) {
            (address mainCoin, uint256 mainCoinAmount) = dealProvider.poolIdToDeal(poolId - 1);
            // create new main coins pool
            uint256 withdrawMainCoinAmount = _calcAmount(withdrawnAmount, _calcRate(tokenAmount, mainCoinAmount));
            // create new pool for the main withdrawn coins
            uint256 mainCoinPoolId = lockDealNFT.mint(lockDealNFT.ownerOf(poolId - 1), mainCoin, msg.sender, 0, address(dealProvider));
            dealProvider.split(poolId - 1, mainCoinPoolId, withdrawMainCoinAmount);
        }
    }
}