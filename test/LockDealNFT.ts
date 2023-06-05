import { expect } from "chai";
import { constants } from "ethers";
import { ethers } from 'hardhat';
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT";
import { DealProvider } from "../typechain-types/contracts/DealProvider";
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockVaultManager } from "../typechain-types/contracts/test/MockVaultManager";
import { deployed } from "./helper";

describe("LockDealNFT", function () {
    let lockDealNFT: LockDealNFT
    let poolId: number
    let token: ERC20Token
    let mockVaultManager: MockVaultManager
    let dealProvider: DealProvider
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let notOwner: SignerWithAddress

    before(async () => {
        ;[notOwner, receiver, newOwner] = await ethers.getSigners()
        mockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        await token.approve(dealProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManager.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
    })

    it("check NFT name", async () => {
        expect(await lockDealNFT.name()).to.equal("LockDealNFT")
    })

    it("check NFT symbol", async () => {
        expect(await lockDealNFT.symbol()).to.equal("LDNFT")
    })

    it("should set provider address", async () => {
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        expect(await lockDealNFT.approvedProviders(dealProvider.address)).to.be.true
    })

    it("should mint new token", async () => {
        await dealProvider.createNewPool(receiver.address, token.address, ["1000"])
        expect(await lockDealNFT.totalSupply()).to.equal(poolId + 1)
    })

    it("only provider can mint", async () => {
        await expect(
            lockDealNFT.connect(notOwner).mint(receiver.address, notOwner.address, token.address, 10)
        ).to.be.revertedWith("Provider not approved")
    })

    it("should revert not approved amount", async () => {
        await token.approve(mockVaultManager.address, "0")
        await expect(dealProvider.createNewPool(receiver.address, token.address, ["1000"])).to.be.revertedWith(
            "Sending tokens not approved"
        )
        await token.approve(mockVaultManager.address, constants.MaxUint256)
    })
})
