// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ProviderInterface/IProviderSingleIdRegistrar.sol";
import "../ProviderInterface/IFundsManager.sol";
import "./CollateralModifiers.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CollateralProvider is IProviderSingleIdRegistrar, CollateralModifiers, IFundsManager, ERC721Holder {
    ///@dev withdraw tokens
    constructor(address _lockDealNFT, address _dealProvider) {
        require(
            _lockDealNFT != address(0x0) && _dealProvider != address(0x0),
            "invalid address"
        );
        lockDealNFT = LockDealNFT(_lockDealNFT);
        dealProvider = DealProvider(_dealProvider);
    }

    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    )
        external
        override
        onlyProvider
        validProviderId(poolId)
        validParamsLength(params.length, currentParamsTargetLenght())
    {
        _registerPool(poolId, params);
    }

    ///@dev each provider decides how many parameters it needs by overriding this function
    ///@param params[0] = StartAmount
    ///@param params[1] = FinishTime
    function _registerPool(uint256 poolId, uint256[] memory params) internal {
        require(
            block.timestamp <= params[1],
            "start time must be in the future"
        );
        require(poolId == lockDealNFT.totalSupply() - 1, "invalid params");
        startTimes[poolId] = params[1];
        lockDealNFT.mintForProvider(address(this), address(dealProvider)); //Main Coin Collector poolId + 1
        lockDealNFT.mintForProvider(address(this), address(dealProvider)); //Token Collector poolId + 2
        uint256 mainCoinHolderId = lockDealNFT.mintForProvider(
            address(this),
            address(dealProvider)
        ); //hold main coin for the project owner poolId + 3
        dealProvider.registerPool(mainCoinHolderId, params); // just need the 0 index, left amount
        assert(mainCoinHolderId == poolId + 3);
        //need to call this from the refund, then call copyVaultId to this Id's
        //poolId + 1 and poolId + 3 is the main coin and poolId + 2 is the token
    }

    // this need to give the project owner to get the tokens that in the poolId + 2
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256, bool isFinal) {
        address projectOwner = lockDealNFT.ownerOf(poolId);
        (uint256 mainCoinCollectorId, uint256 tokenCollectorId, uint256 mainCoinHolderId) = getInnerIds(poolId);
        //check for time
        if (startTimes[poolId] < block.timestamp) {
            // Finish Refund
            lockDealNFT.transferFrom(address(this), projectOwner, mainCoinCollectorId);
            lockDealNFT.transferFrom(address(this), projectOwner, tokenCollectorId);
            lockDealNFT.transferFrom(address(this), projectOwner, mainCoinHolderId);
            isFinal = true;
        } else {
            // the refund phase is not finished yet
            _split(mainCoinCollectorId, projectOwner);
            _split(tokenCollectorId, projectOwner);
        }
    }

    function split(
        uint256,
        uint256,
        uint256
    ) external override pure {
        revert("not implemented");
    }

    function _split(uint256 poolId, address owner) internal {
        uint256 amount = dealProvider.getParams(poolId)[0];
        if (amount > 0) {
            lockDealNFT.split(poolId, amount, owner);
        }
    }

    function handleRefund(
        uint256 poolId,
        uint256 tokenAmount,
        uint256 mainCoinAmount
    ) public override onlyProvider validProviderId(poolId) {
        (, uint256 tokenCollectorId, uint256 mainCoinHolderId) = getInnerIds(poolId);
        dealProvider.withdraw(mainCoinHolderId, mainCoinAmount);
        _deposit(tokenCollectorId, tokenAmount);
    }

    function handleWithdraw(
        uint256 poolId,
        uint256 mainCoinAmount
    ) public override onlyProvider validProviderId(poolId) {
        uint256 mainCoinCollectorId = poolId + 1;
        uint256 mainCoinHolderId = poolId + 3;
        dealProvider.withdraw(mainCoinHolderId, mainCoinAmount);
        _deposit(mainCoinCollectorId, mainCoinAmount);
    }

    function _deposit(uint256 poolId, uint256 amount) internal {
        uint256[] memory params = dealProvider.getParams(poolId);
        params[0] += amount;
        dealProvider.registerPool(poolId, params);
    }
}