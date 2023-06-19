// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "../ProviderInterface/IProviderSingleIdRegistrar.sol";
import "../ProviderInterface/IProvider.sol";
import "../Provider/ProviderModifiers.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract RefundProvider is RefundState, ProviderModifiers, IProvider, ERC721Holder {
    constructor(address nftContract, address provider) {
        require(nftContract != address(0x0) && provider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(nftContract);
        lockProvider = LockDealProvider(provider);
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
        uint256 providerLength = params.length;
        require(providerLength > 2, "invalid params length");

        /// Hold token (data) | Owner Refund
        uint256 dataPoolID = lockDealNFT.mint(address(this), token, msg.sender, 0, provider);
        IProviderSingleIdRegistrar(provider).registerPool(dataPoolID, address(this), token, params);

        /// Hold main coin | Owner Refund
        uint256 [] memory mainCoinParams = new uint256[](2);
        mainCoinParams[0] = params[providerLength - 2];
        mainCoinParams[1] = params[providerLength - 1];
        uint256 lockProviderPoolId = lockDealNFT.mint(msg.sender, mainCoin, msg.sender, mainCoinParams[0], address(lockProvider));
        lockProvider.registerPool(lockProviderPoolId, address(this), mainCoin, mainCoinParams);

        ///  Hold tokens | real owner poolId
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0], address(this));
        IProviderSingleIdRegistrar(provider).registerPool(poolId, owner, token, params);
    }

    ///@dev the user splits his tokens into main coins
    function split(
        uint256 poolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external onlyNFT {
        require(lockProvider.startTimes(poolId - 1) <= block.timestamp, "can't split after refund finish time");
        // get data from token, mainCoin pools
        (, uint256 tokenAmount) = lockProvider.dealProvider().poolIdToDeal(poolId - 2);
        (address mainCoin, uint256 mainCoinAmount) = lockProvider.dealProvider().poolIdToDeal(poolId - 1);
        address provider = lockDealNFT.poolIdToProvider(poolId - 2);

        // user reduce his token balance
        LockDealProvider(provider).withdraw(poolId, splitAmount);

        // user reduce main coin balance
        uint256 rate = calcRate(tokenAmount, mainCoinAmount);
        uint256 refundAmount = calcAmount(splitAmount, rate);
        lockProvider.dealProvider().withdraw(poolId - 1, refundAmount);

        // user creates new refund pool for himself
        address owner = lockDealNFT.ownerOf(poolId);
        uint256 [] memory params = new uint256[](lockProvider.currentParamsTargetLenght());
        params[0] = refundAmount;
        IProviderSingleIdRegistrar(provider).registerPool(newPoolId, owner, mainCoin, params);
        // project owner tokens amount is updated
    }

    function calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return (tokenAValue * 1e18) / tokenBValue;
    }

    function calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return amount * 1e18 / rate;
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        // user can't call a poolId that doesn't belong to him
        // project owner can call lockProvider poolId when refund finish time is over
        //  /________________________________,-```-,
        //  | poolId = refundProvider        |     |
        //  | (poolId - 1) = LockDealProvider|     |
        //  | (poolId - 2) = data holder     |     |
        //  \_______________________________/_____/
        address provider = lockDealNFT.poolIdToProvider(poolId - 2);
        // user withdraws his token from the provider by cascading providers params
        (withdrawnAmount, isFinal) = IProvider(provider).withdraw(poolId);
    }

    

    // ///@dev the owner of the project can take the tokens that the user has exchanged for the refund coins
    // function withdrawTokens(uint256 poolId) external {
    //     require(msg.sender == lockDealNFT.ownerOf(poolId - 1), "only project owner can withdraw tokens");
    //     require(lockProvider.startTimes(poolId - 1) > block.timestamp, "can't split after refund finish time");
    //     (address token, ) = lockProvider.dealProvider().poolIdToDeal(poolId);

    //     uint256 [] memory params = new uint256[](2);
    //     lockProvider.registerPool(poolId - 2, address(0), token, params);
    //     uint256 refundPoolID = lockDealNFT.mint(msg.sender, token, msg.sender, refundAmounts[poolId], address(lockProvider));
    //     lockDealNFT.withdraw(refundPoolID);
    // }

    function getData(
        uint256 poolId
    ) external view override returns (
        IDealProvierEvents.BasePoolInfo memory poolInfo,
        uint256[] memory params
    ) {

    }
}
