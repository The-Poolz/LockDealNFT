// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "../interfaces/IBeforeTransfer.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../SimpleProviders/DealProvider/DealProviderState.sol";
import "../util/CalcUtils.sol";

contract DelayVaultProvider is IProvider, IBeforeTransfer, IERC165, DealProviderState {
    using CalcUtils for uint256;

    constructor(ILockDealNFT _nftContract, ProviderData[] memory _providersData) {
        nftContract = _nftContract;
        typesCount = uint8(_providersData.length);
        for (uint8 i = 0; i < typesCount; i++) {
            require(address(_providersData[i].provider) != address(0x0), "invalid address");
            require(
                _providersData[i].provider.currentParamsTargetLenght() == _providersData[i].params.length + 1,
                "invalid params length"
            );
            TypeToProviderData[i] = _providersData[i];
        }
    }

    mapping(uint256 => address) internal LastPoolOwner;
    mapping(address => uint256[]) internal UserToTotalAmount; //will be {typesCount} lentgh
    mapping(uint256 => uint8) internal PoolToType;
    mapping(uint8 => ProviderData) internal TypeToProviderData; //will be {typesCount} lentgh
    uint8 public typesCount;
    ILockDealNFT public nftContract;
    //this is onlty the delta
    //the amount taken from the user is the amount of the pool
    // params[0] = startTimeDelta (empty for DealProvider)
    // params[1] = endTimeDelta (only for TimedLockDealProvider)
    struct ProviderData {
        IProvider provider;
        uint256[] params;
    }

    function withdraw(uint256 tokenId) external override returns (uint256 withdrawnAmount, bool isFinal) {
        uint8 theType = PoolToType[tokenId];
        address owner = LastPoolOwner[tokenId];
        uint256 newPoolId = nftContract.mintForProvider(owner, TypeToProviderData[theType].provider);
        uint256[] memory settings = TypeToProviderData[theType].params;
        uint256[] memory params = new uint256[](settings.length + 1);
        params[0] = poolIdToAmount[tokenId];
        for (uint256 i = 0; i < settings.length; i++) {
            params[i + 1] = block.timestamp + settings[i];
        }
        TypeToProviderData[theType].provider.registerPool(newPoolId, params);
        isFinal = true;
        withdrawnAmount = poolIdToAmount[tokenId] = 0;
        UserToTotalAmount[owner][theType] -= params[0];
        //This need to make a new pool without transfering the token, the pool data is taken from the settings
    }

    function beforeTransfer(address from, address to, uint256 poolId /*NonReentry*/) external override {
        if (to == address(nftContract)) LastPoolOwner[poolId] = from;
        else {
            _handleTransfer(from, to, poolId);
        }
    }

    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) external override {
        address oldOwner = LastPoolOwner[oldPoolId];
        address newOwner = nftContract.ownerOf(newPoolId);
        uint256 amount = poolIdToAmount[oldPoolId].calcAmount(ratio);
        poolIdToAmount[oldPoolId] -= amount;
        poolIdToAmount[newPoolId] = amount;
        PoolToType[newPoolId] = PoolToType[oldPoolId];
        if (newOwner != oldOwner) {
            _handleTransfer(oldOwner, newOwner, oldPoolId);
        }
    }

    function _handleTransfer(address from, address to, uint256 poolId) internal returns (uint256 amount) {
        uint8 theType = PoolToType[poolId];
        amount = poolIdToAmount[poolId];
        UserToTotalAmount[from][theType] -= amount;
        UserToTotalAmount[to][theType] += amount;
    }

    function registerPool(uint256 poolId, uint256[] calldata params) external override {
        uint8 theType = uint8(params[1]);
        uint256 amount = params[0];
        require(PoolToType[poolId] == 0, "pool already registered");
        require(params.length == 2, "invalid params length");
        PoolToType[poolId] = theType;
        UserToTotalAmount[nftContract.ownerOf(poolId)][theType] += amount;
        poolIdToAmount[poolId] = amount;
    }

    function getParams(uint256 poolId) external view override returns (uint256[] memory params) {
        params = new uint256[](2);
        params[0] = poolIdToAmount[poolId];
        params[1] = uint256(PoolToType[poolId]);
    }

    function getWithdrawableAmount(uint256 poolId) external view override returns (uint256 withdrawalAmount) {
        withdrawalAmount = poolIdToAmount[poolId];
    }

    function currentParamsTargetLenght() external pure override returns (uint256) {
        return 2;
    }

    function name() external pure override returns (string memory) {
        return "DelayVaultProvider";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IBeforeTransfer).interfaceId;
    }

    function UpgradeType(uint256 PoolId, uint8 newType) external {
        require(nftContract.poolIdToProvider(PoolId) == this, "need to be THIS provider");
        require(PoolToType[PoolId] != 0, "pool not registered");
        require(msg.sender == nftContract.ownerOf(PoolId), "only the Owner can upgrade the type");
        require(newType > PoolToType[PoolId], "new type must be bigger than the old one");
        require(newType <= typesCount, "new type must be smaller than the types count");
        PoolToType[PoolId] = newType;
    }
}
