// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "../interfaces/IProvider.sol"; //TODO  work with interface instead of contract
//import "../interfaces/ILockDealNFT.sol"; //TODO  work with interface instead of contract
import "../LockDealNFT/LockDealNFT.sol";
import "../AdvancedProviders/RefundProvider/RefundProvider.sol";
import "../AdvancedProviders/CollateralProvider/CollateralProvider.sol";
import "../AdvancedProviders/LockDealBundleProvider/LockDealBundleProvider.sol";

/// @title RefundBundleBuilder contract
/// @notice Implements a contract for building refund bundles
contract RefundBundleBuilder is ERC721Holder {
    LockDealNFT public lockDealNFT;
    RefundProvider public refundProvider;
    LockDealBundleProvider public bundleProvider;
    CollateralProvider public collateralProvider;

    constructor(address _nft,address _refund, address _bundle, address _collateral) 
    {
        lockDealNFT = LockDealNFT(_nft);
        refundProvider = RefundProvider(_refund);
        bundleProvider = LockDealBundleProvider(_bundle);
        collateralProvider = CollateralProvider(_collateral);
    }

    struct UserSplit {
        address user;
        uint256 amount;
    }

    function _calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return (tokenAValue * 1e18) / tokenBValue;
    }

    // address[0] = token
    // address[1] = mainCoin
    // address[2+] = provider
    // params[0][0-1] = collateral params, [0] start amount, [1] finish time
    // refund params - collateralId, generate. rate, calculate.
    // params[1+][0] - the sum need to be equal to the token amount (sum of userSplits)
    function buildRefundBundle(
    UserSplit[] memory userSplits,
    address[] memory addressParams,
    uint256[][] memory params)
    public {
        //TODO require lenghts

        address token = addressParams[0];
        address mainCoin = addressParams[1];

        uint256 tokenAmount = 0;
        for (uint256 i = 0; i < userSplits.length; i++) {
            tokenAmount += userSplits[i].amount;
        }
        uint256 mainCoinAmount = params[0][0];
        uint256[] memory collateralParams = params[0];
                // Hold main coin | Project Owner 
        uint256 collateralPoolId = lockDealNFT.mintAndTransfer(msg.sender, mainCoin, msg.sender, collateralParams[0], collateralProvider);
        collateralProvider.registerPool(collateralPoolId, collateralParams);

        uint256[] memory refundRegisterParams = new uint256[](2);
        refundRegisterParams[0] = collateralPoolId;
        refundRegisterParams[1] = _calcRate(tokenAmount, mainCoinAmount);

        uint256 refundPoolId = lockDealNFT.mintAndTransfer(address(this), token, msg.sender, tokenAmount, refundProvider);
        uint256 bundlePoolId = lockDealNFT.mintForProvider(address(refundProvider), bundleProvider);

        for (uint256 i = 2; i < addressParams.length; ++i) {
            IProvider provider = IProvider(addressParams[i]);
            uint256 innerPoolId = lockDealNFT.mintForProvider(address(bundleProvider), provider);
            uint256[] memory innerParams = params[i - 1];
            provider.registerPool(innerPoolId, innerParams);
        }

        refundProvider.registerPool(refundPoolId, refundRegisterParams);
        uint256[] memory bundleParams = new uint256[](1);
        bundleParams[0] = lockDealNFT.tokenIdCounter() - 1;
        bundleProvider.registerPool(bundlePoolId, bundleParams);

        lockDealNFT.copyVaultId(collateralPoolId, collateralPoolId + 1);
        lockDealNFT.copyVaultId(refundPoolId, collateralPoolId + 2);
        lockDealNFT.copyVaultId(collateralPoolId, collateralPoolId + 3);
  
        for (uint256 i = 0; i < userSplits.length; ++i) {
            uint256 userAmount = userSplits[i].amount;
            address user = userSplits[i].user;
            lockDealNFT.split(refundPoolId, userAmount, user);
        }
    }
}