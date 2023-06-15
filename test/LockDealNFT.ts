import { expect } from "chai";
import { constants } from "ethers";
import { ethers } from 'hardhat';
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT";
import { DealProvider } from "../typechain-types/contracts/DealProvider";
import { LockDealProvider } from "../typechain-types/contracts/LockProvider";
import { TimedDealProvider } from "../typechain-types/contracts/TimedDealProvider";
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
    let lockDealProvider: LockDealProvider
    let timedDealProvider: TimedDealProvider
    let receiver: SignerWithAddress
    let notOwner: SignerWithAddress
    const amount: string = "1000"

    before(async () => {
        [notOwner, receiver] = await ethers.getSigners()
        mockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockDealProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedDealProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockDealProvider.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        await token.approve(dealProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManager.address, constants.MaxUint256)
        await token.approve(lockDealProvider.address, constants.MaxUint256)
        await token.approve(timedDealProvider.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockDealProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedDealProvider.address, true)
        await lockDealNFT.setApprovedProvider(mockVaultManager.address, true)
    })

    beforeEach(async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await dealProvider.createNewPool(receiver.address, token.address, [amount])
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

    it("should return ProviderApproved event", async () => {
        const tx = await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await tx.wait()
        const events = await lockDealNFT.queryFilter(lockDealNFT.filters.ProviderApproved())
        expect(events[events.length - 1].args.status).to.equal(true)
        expect(events[events.length - 1].args.provider).to.equal(dealProvider.address)
    })

    it("should mint new token", async () => {
        expect(await lockDealNFT.totalSupply()).to.equal(poolId + 1)
    })

    it("should return mintInitiated event", async () => {
        const tx = await dealProvider.createNewPool(receiver.address, token.address, [amount])
        await tx.wait()
        const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MintInitiated())
        expect(events[events.length - 1].args.provider).to.equal(dealProvider.address)
    })

    it("should save provider address", async () => {
        expect(await lockDealNFT.poolIdToProvider(poolId)).to.equal(dealProvider.address)
    })

    it("only provider can mint", async () => {
        await expect(
            lockDealNFT.connect(notOwner).mint(receiver.address, notOwner.address, token.address, 10, dealProvider.address)
        ).to.be.revertedWith("Provider not approved")
    })

    it("should revert not approved amount", async () => {
        await token.approve(mockVaultManager.address, "0")
        await expect(dealProvider.createNewPool(receiver.address, token.address, [amount])).to.be.revertedWith(
            "Sending tokens not approved"
        )
        await token.approve(mockVaultManager.address, constants.MaxUint256)
    })

    it("should return data from DealProvider using LockedDealNFT", async () => {
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.deep.equal(dealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address])
        expect(poolData.params[0]).to.equal(amount)
    })

    it("should return data from LockDealProvider using LockedDealNFT", async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await lockDealProvider.createNewPool(receiver.address, token.address, [amount, 1])
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.deep.equal(lockDealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address])
        expect(poolData.params[0]).to.equal(amount)
        expect(poolData.params[1]).to.equal(1)
    })

    it("should return data from TimedDealProvider using LockedDealNFT", async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await timedDealProvider.createNewPool(receiver.address, token.address, [amount, 1, 1, amount])
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.deep.equal(timedDealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address])
        expect(poolData.params[0]).to.equal(amount)
        expect(poolData.params[1]).to.equal(1)
        expect(poolData.params[2]).to.equal(1)
        expect(poolData.params[3]).to.equal(amount)
    })
})
