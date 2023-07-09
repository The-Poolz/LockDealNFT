// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ProviderInterface/IProviderSingleIdRegistrar.sol";
import "../Provider/ProviderState.sol";
import "../LockProvider/LockDealState.sol";

contract CollateralProvider is
    IProviderSingleIdRegistrar,
    LockDealState,
    ProviderState
{
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
    ) external /** TODO add Only Aprove provider**/ override {
        _registerPool(poolId, params);
    }

    ///@dev each provider decides how many parameters it needs by overriding this function
    ///@param params[0] = StartAmount
    ///@param params[1] = FinishTime
    function _registerPool(uint256 poolId, uint256[] memory params) internal {
        require(block.timestamp <= params[1], "start time must be in the future");
        require(
            address(lockDealNFT.providerOf(poolId)) == address(this),
            "Invalid provider"
        );
        require(
            poolId == lockDealNFT.totalSupply(),
            "_registerPool only for new id's"
        );
        //address projcetOwner = lockDealNFT.ownerOf(poolId); 
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

    // this need to give the projecet owner to get the tokens that in the poolId + 2
    function withdraw(
        uint256 poolId
    ) public /** TODO add Only NFT **/ returns (uint256 withdrawnAmount, bool isFinal) {
        address projcetOwner = lockDealNFT.ownerOf(poolId);
        uint256 mainCoinCollectorId = poolId + 1;
        uint256 tokenCollectorId = poolId + 2;
        uint256 mainCoinHolderId = poolId + 3;
        //check for time
        if (startTimes[poolId] < block.timestamp) {
            // Finish Refound
            lockDealNFT.transferFrom(
                address(this),
                projcetOwner,
                mainCoinCollectorId
            );
            lockDealNFT.transferFrom(
                address(this),
                projcetOwner,
                tokenCollectorId
            );
            lockDealNFT.transferFrom(
                address(this),
                projcetOwner,
                mainCoinHolderId
            );
            isFinal = true;
        } else {
            // the refound phase is not finished yet
            uint256 mainCoinAmount = dealProvider.getParams(
                mainCoinCollectorId
            )[0];
            uint256 tokenAmount = dealProvider.getParams(tokenCollectorId)[0];
            lockDealNFT.split(
                mainCoinCollectorId,
                mainCoinAmount,
                projcetOwner
            );
            lockDealNFT.split(
                tokenCollectorId,
                 tokenAmount,
                  projcetOwner);
        }
    }

    function getParams(
        uint256 poolId
    ) public view returns (uint256[] memory params) {
        params = new uint256[](3);
        params[0] = dealProvider.getParams(poolId)[0];
        params[1] = startTimes[poolId];
    }
}
