// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IFundsManager.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./CollateralState.sol";
import "../../util/CalcUtils.sol";
import "@ironblocks/firewall-consumer/contracts/FirewallConsumer.sol";

contract CollateralProvider is IFundsManager, ERC721Holder, CollateralState, FirewallConsumer {
    using CalcUtils for uint256;

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
        external
        override
        firewallProtected
        onlyProvider
        validProviderId(poolId)
        validParamsLength(params.length, currentParamsTargetLength())
    {
        _registerPool(poolId, params);
    }

    /// @dev Each provider decides how many parameters it needs by overriding this function.
    /// @param params[0] = token amount
    /// @param params[params.length - 2] = main coin amount
    /// @param params[params.length - 1] = FinishTime
    function _registerPool(uint256 poolId, uint256[] calldata params)
        internal
        firewallProtectedSig(0x8b60dedb)
    {
        uint256 tokenAmount = params[0];
        uint256 mainCoinAmount = params[params.length - 2];
        uint256 finishTime = params[params.length - 1];

        require(block.timestamp <= finishTime, "start time must be in the future");
        require(poolId == lockDealNFT.totalSupply() - 1, "Invalid poolId");

        // rate - exchange rate between the main coin (USDT) and the token
        // rate = (mainCoinAmount * 1e21) / tokenAmount
        // 1e21 is the precision where 1e21 = 100% = 1:1 | 1e20 = 10% = 0.1:1
        // 1e22 = 1000% = 10:1 | 1e19 = 1% = 0.01:1
        uint256 rate = mainCoinAmount.calcRate(tokenAmount);
        uint256 mainCoinHolderId = _mintNFTs();

        _setPoolProperties(poolId, rate, finishTime, mainCoinAmount);
        _cloneVaultIds(poolId);

        assert(mainCoinHolderId == poolId + 3);
        emit UpdateParams(poolId, params);
    }

    function _setPoolProperties(uint256 poolId, uint256 rate, uint256 finishTime, uint256 mainCoinAmount)
        private
        firewallProtectedSig(0x91666b02)
    {
        poolIdToRateToWei[poolId] = rate;
        poolIdToTime[poolId] = finishTime;
        uint256[] memory mainCoinParams = new uint256[](1);
        mainCoinParams[0] = mainCoinAmount;
        provider.registerPool(poolId + 3, mainCoinParams); // Just need the 0 index, token left amount
    }

    function _mintNFTs() private firewallProtectedSig(0x1cd0f8c5) returns (uint256 poolId) {
        lockDealNFT.mintForProvider(address(this), provider); // Main Coin Collector
        lockDealNFT.mintForProvider(address(this), provider); // Token Collector
        poolId = lockDealNFT.mintForProvider(address(this), provider);
    }

    function _cloneVaultIds(uint256 mainCoinPoolId) private firewallProtectedSig(0x720a8731) {
        lockDealNFT.cloneVaultId(mainCoinPoolId + 1, mainCoinPoolId);
        lockDealNFT.cloneVaultId(mainCoinPoolId + 3, mainCoinPoolId);
    }

    // this need to give the project owner to get the tokens that in the poolId + 2
    function withdraw(uint256 poolId) public view override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        isFinal = isPoolFinished(poolId);
        // LockDealNFT uses getInnerIdsArray to get the withdraw amount
        withdrawnAmount = 0;
    }

    ///@dev newPoolId is collateral provider
    function split(uint256 poolId, uint256, uint256 ratio) external override firewallProtected onlyNFT {
        (uint256 mainCoinCollectorId, uint256 tokenCollectorId, uint256 mainCoinHolderId) = getInnerIds(poolId);
        uint256 tokenCollectorAmount = provider.getWithdrawableAmount(tokenCollectorId);
        uint256 coinCollectorAmount = provider.getWithdrawableAmount(mainCoinCollectorId);
        uint256 coinHolderAmount = isPoolFinished(poolId) ? provider.getWithdrawableAmount(mainCoinHolderId) : 0;
        require(coinHolderAmount + coinCollectorAmount + tokenCollectorAmount > 0, "pools are empty");
        _splitter(coinCollectorAmount, mainCoinCollectorId, ratio);
        _splitter(tokenCollectorAmount, tokenCollectorId, ratio);
        _splitter(coinHolderAmount, mainCoinHolderId, ratio);
    }

    function _splitter(uint256 amount, uint256 poolId, uint256 ratio) internal firewallProtectedSig(0x203fb415) {
        if (amount > 0) {
            lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), poolId, abi.encode(ratio));
        } else {
            lockDealNFT.mintForProvider(address(this), provider);
        }
    }

    function handleRefund(
        uint256 poolId,
        address user,
        uint256 tokenAmount
    ) external override firewallProtected onlyProvider validProviderId(poolId) {
        (, uint256 tokenCollectorId, uint256 mainCoinHolderId) = getInnerIds(poolId);
        uint256 mainCoinAmount = tokenAmount.calcAmount(poolIdToRateToWei[poolId]);
        provider.withdraw(mainCoinHolderId, mainCoinAmount);
        _deposit(tokenCollectorId, tokenAmount);
        uint256 newMainCoinPoolId = lockDealNFT.mintForProvider(user, provider);
        uint256[] memory params = new uint256[](1);
        params[0] = mainCoinAmount;
        provider.registerPool(newMainCoinPoolId, params);
        lockDealNFT.cloneVaultId(newMainCoinPoolId, mainCoinHolderId);
    }

    function handleWithdraw(uint256 poolId, uint256 tokenAmount) external override firewallProtected onlyProvider validProviderId(poolId) {
        (uint256 mainCoinCollectorId, , uint256 mainCoinHolderId) = getInnerIds(poolId);
        uint256 mainCoinAmount = tokenAmount.calcAmount(poolIdToRateToWei[poolId]);
        provider.withdraw(mainCoinHolderId, mainCoinAmount);
        _deposit(mainCoinCollectorId, mainCoinAmount);
    }

    function _deposit(uint256 poolId, uint256 amount) internal firewallProtectedSig(0xf3207723) {
        uint256[] memory params = provider.getParams(poolId);
        params[0] += amount;
        provider.registerPool(poolId, params);
    }
}
