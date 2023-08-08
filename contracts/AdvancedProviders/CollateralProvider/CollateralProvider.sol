// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IFundsManager.sol";
import "./CollateralModifiers.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CollateralProvider is CollateralModifiers, IFundsManager, ERC721Holder {
    ///@dev withdraw tokens
    constructor(ILockDealNFT _lockDealNFT, address _dealProvider) {
        require(address(_lockDealNFT) != address(0x0) && _dealProvider != address(0x0), "invalid address");
        lockDealNFT = _lockDealNFT;
        provider = ISimpleProvider(_dealProvider);
        name = "CollateralProvider";
    }

    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    )
        public
        override
        onlyProvider
        validProviderId(poolId)
        validParamsLength(params.length, currentParamsTargetLenght())
    {
        _registerPool(poolId, params);
        lockDealNFT.updateProviderMetadata(poolId);
    }

    ///@dev each provider decides how many parameters it needs by overriding this function
    ///@param params[0] = StartAmount
    ///@param params[1] = FinishTime
    function _registerPool(uint256 poolId, uint256[] calldata params) internal override {
        require(block.timestamp <= params[1], "start time must be in the future");
        require(poolId == lockDealNFT.totalSupply() - 1, "invalid params");
        poolIdToTime[poolId] = params[1];
        lockDealNFT.mintForProvider(address(this), provider); //Main Coin Collector poolId + 1
        lockDealNFT.mintForProvider(address(this), provider); //Token Collector poolId + 2
        uint256 mainCoinHolderId = lockDealNFT.mintForProvider(address(this), provider); //hold main coin for the project owner poolId + 3
        provider.registerPool(mainCoinHolderId, params); // just need the 0 index, left amount
        assert(mainCoinHolderId == poolId + 3);
        //need to call this from the refund, then call copyVaultId to this Id's
        //poolId + 1 and poolId + 3 is the main coin and poolId + 2 is the token
    }

    // this need to give the project owner to get the tokens that in the poolId + 2
    function withdraw(
        address,
        address from,
        uint256 poolId,
        bytes calldata
    ) public override onlyNFT returns (uint256, bool isFinal) {
        (uint256 mainCoinCollectorId, uint256 tokenCollectorId, uint256 mainCoinHolderId) = getInnerIds(poolId);
        //check for time
        if (poolIdToTime[poolId] < block.timestamp) {
            // Project owner receives tokens
            lockDealNFT.withdrawFromProvider(from, mainCoinCollectorId);
            lockDealNFT.withdrawFromProvider(from, tokenCollectorId);
            lockDealNFT.withdrawFromProvider(from, mainCoinHolderId);
            lockDealNFT.updateProviderMetadata(poolId);
            isFinal = true;
        } else {
            // the refund phase is not finished yet
            _split(mainCoinCollectorId, from);
            _split(tokenCollectorId, from);
        }
    }

    function split(uint256 poolId, uint256 newPoolId, uint256 ratio) external override onlyNFT {
        (uint256 mainCoinCollectorId, uint256 tokenCollectorId, uint256 mainCoinHolderId) = getInnerIds(poolId);
        uint256 tokenCollectorAmount = provider.getParams(tokenCollectorId)[0];
        uint256 coinCollectorAmount = provider.getParams(mainCoinCollectorId)[0];
        uint256 coinHolderAmount = provider.getParams(mainCoinHolderId)[0];
        require(coinHolderAmount + coinCollectorAmount + tokenCollectorAmount > 0, "pools are empty");
        //save time for new Collateral
        poolIdToTime[newPoolId] = poolIdToTime[poolId];
        _splitter(coinCollectorAmount, mainCoinCollectorId, ratio);
        _splitter(tokenCollectorAmount, tokenCollectorId, ratio);
        _splitter(coinHolderAmount, mainCoinHolderId, ratio);
    }

    function _splitter(uint256 amount, uint256 poolId, uint256 ratio) internal {
        if (amount > 0) {
            lockDealNFT.selfSplit(poolId, ratio);
        } else {
            lockDealNFT.mintForProvider(address(this), provider);
        }
    }

    function _split(uint256 poolId, address owner) internal {
        uint256 amount = provider.getParams(poolId)[0];
        if (amount > 0) {
            uint256 rate = 1e18; // 100% of the left amount
            (uint256 newPoolID, ) = lockDealNFT.split(poolId, rate, owner);
            lockDealNFT.transferFromProvider(owner, newPoolID);
        }
    }

    function handleRefund(
        uint256 poolId,
        uint256 tokenAmount,
        uint256 mainCoinAmount
    ) public override onlyProvider validProviderId(poolId) {
        (, uint256 tokenCollectorId, uint256 mainCoinHolderId) = getInnerIds(poolId);
        provider.withdraw(mainCoinHolderId, mainCoinAmount);
        _deposit(tokenCollectorId, tokenAmount);
    }

    function handleWithdraw(
        uint256 poolId,
        uint256 mainCoinAmount
    ) public override onlyProvider validProviderId(poolId) {
        uint256 mainCoinCollectorId = poolId + 1;
        uint256 mainCoinHolderId = poolId + 3;
        provider.withdraw(mainCoinHolderId, mainCoinAmount);
        _deposit(mainCoinCollectorId, mainCoinAmount);
    }

    function _deposit(uint256 poolId, uint256 amount) internal {
        uint256[] memory params = provider.getParams(poolId);
        params[0] += amount;
        provider.registerPool(poolId, params);
    }
}
