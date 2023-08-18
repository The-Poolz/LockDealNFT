// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../AdvancedProviders/CollateralProvider/IInnerWithdraw.sol";

/// @title LockDealNFT contract
/// @notice Implements a non-fungible token (NFT) contract for locking deals
contract LockDealNFT is LockDealNFTModifiers, IERC721Receiver {
    constructor(address _vaultManager, string memory _baseURI) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultManager != address(0x0), "invalid vault manager address");
        vaultManager = IVaultManager(_vaultManager);
        approvedProviders[address(this)] = true;
        baseURI = _baseURI;
    }

    function mintForProvider(
        address owner,
        IProvider provider
    ) external onlyApprovedProvider notZeroAddress(owner) returns (uint256 poolId) {
        if (address(provider) != msg.sender) {
            _onlyApprovedProvider(provider);
        }
        poolId = _mint(owner, provider);
    }

    function mintAndTransfer(
        address owner,
        address token,
        address from,
        uint256 amount,
        IProvider provider
    )
        public
        onlyApprovedProvider
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        require(amount < type(uint256).max, "amount is too big");
        if (address(provider) != msg.sender) {
            _onlyApprovedProvider(provider);
        }
        poolId = _mint(owner, provider);
        poolIdToVaultId[poolId] = vaultManager.depositByToken(token, from, amount);
    }

    function copyVaultId(
        uint256 fromId,
        uint256 toId
    ) external onlyApprovedProvider validPoolId(fromId) validPoolId(toId) {
        poolIdToVaultId[toId] = poolIdToVaultId[fromId];
    }

    /// @dev Sets the approved status of a provider
    /// @param provider The address of the provider
    /// @param status The new approved status (true or false)
    function setApprovedProvider(IProvider provider, bool status) external onlyOwner onlyContract(address(provider)) {
        approvedProviders[address(provider)] = status;
        emit ProviderApproved(provider, status);
    }

    function approvePoolTransfers(bool status) external {
        require(approvedPoolUserTransfers[msg.sender] != status, "status is the same as before");
        approvedPoolUserTransfers[msg.sender] = status;
    }

    ///@dev withdraw implementation
    function onERC721Received(
        address,
        address from,
        uint256 poolId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(this), "invalid nft contract");
        bool isFinal;
        if (data.length > 0) {
            (uint256 ratio, address newOwner) = parseData(data, from);
            isFinal = _split(poolId, ratio, newOwner);
        } else {
            isFinal = _withdrawERC20(from, poolId);
        }
        if (!isFinal) {
            _transfer(address(this), from, poolId);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function _withdrawERC20(address from, uint256 poolId) internal returns (bool isFinal) {
        uint256 withdrawnAmount;
        (withdrawnAmount, isFinal) = poolIdToProvider[poolId].withdraw(poolId);
        if (withdrawnAmount == type(uint256).max) {
            withdrawnAmount = 0;
            uint256[] memory ids = IInnerWithdraw(address(poolIdToProvider[poolId])).getInnerIdsArray(poolId);
            for (uint256 i = 0; i < ids.length; ++i) {
                _withdrawERC20(from, ids[i]);
            }
        }
        if (withdrawnAmount > 0) {
            emit MetadataUpdate(poolId);
            vaultManager.withdrawByVaultId(poolIdToVaultId[poolId], from, withdrawnAmount);
        }
        emit TokenWithdrawn(poolId, from, withdrawnAmount, getData(poolId).params[0]);
    }

    /// @dev Splits a pool into two pools with adjusted amounts
    /// @param poolId The ID of the pool to split
    /// @param ratio The ratio of funds to split into the new pool
    /// @param newOwner The address to assign the new pool to
    function _split(
        uint256 poolId,
        uint256 ratio,
        address newOwner
    ) internal notZeroAmount(ratio) returns (bool isFinal) {
        require(ratio <= 1e18, "split amount exceeded");
        IProvider provider = poolIdToProvider[poolId];
        uint256 newPoolId = _mint(newOwner, provider);
        poolIdToVaultId[newPoolId] = poolIdToVaultId[poolId];
        provider.split(poolId, newPoolId, ratio);
        isFinal = provider.getParams(poolId)[0] == 0;
        emit PoolSplit(
            poolId,
            msg.sender,
            newPoolId,
            newOwner,
            getData(poolId).params[0],
            getData(newPoolId).params[0]
        );
        emit MetadataUpdate(poolId);
    }

    /// @param owner The address to assign the token to
    /// @param provider The address of the provider assigning the token
    /// @return newPoolId The ID of the pool
    function _mint(address owner, IProvider provider) internal returns (uint256 newPoolId) {
        newPoolId = totalSupply();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
        emit MintInitiated(provider);
    }

    function updateAllMetadata() external onlyOwner {
        emit MetadataUpdate(type(uint256).max);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }
}
