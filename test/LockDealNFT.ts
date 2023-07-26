import { expect } from "chai";
import { ethers } from 'hardhat';
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { LockDealNFT } from "../typechain-types";
import { DealProvider } from "../typechain-types";
import { LockDealProvider } from "../typechain-types";
import { TimedDealProvider } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockVaultManager } from "../typechain-types";
import { deployed, token } from "./helper";

describe("LockDealNFT", function () {
    let lockDealNFT: LockDealNFT
    let poolId: number
    let mockVaultManager: MockVaultManager
    let dealProvider: DealProvider
    let lockDealProvider: LockDealProvider
    let timedDealProvider: TimedDealProvider
    let receiver: SignerWithAddress
    let notOwner: SignerWithAddress
    let startTime: number, finishTime: number;
    const amount: string = "1000"

    before(async () => {
        [receiver, notOwner] = await ethers.getSigners()
        mockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address, "")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockDealProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedDealProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockDealProvider.address)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockDealProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedDealProvider.address, true)
        await lockDealNFT.setApprovedProvider(mockVaultManager.address, true)
    })

    beforeEach(async () => {
        startTime = await time.latest() + 100
        finishTime = startTime + 100
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await dealProvider.createNewPool(receiver.address, token, [amount])
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

    it("should set provider", async () => {
        expect(await lockDealNFT.poolIdToProvider(poolId)).to.equal(dealProvider.address)
    })

    it("should return mintInitiated event", async () => {
        const tx = await dealProvider.createNewPool(receiver.address, token, [amount])
        await tx.wait()
        const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MintInitiated())
        expect(events[events.length - 1].args.provider).to.equal(dealProvider.address)
    })

    it("should save provider address", async () => {
        expect(await lockDealNFT.poolIdToProvider(poolId)).to.equal(dealProvider.address)
    })

    it("only provider can mintAndTransfer", async () => {
        await expect(
            lockDealNFT.connect(notOwner).mintAndTransfer(receiver.address, notOwner.address, token, 10, dealProvider.address)
        ).to.be.revertedWith("Provider not approved")
    })

    it("only provider can mintForProvider", async () => {
        await expect(
            lockDealNFT.connect(notOwner).mintForProvider(receiver.address, dealProvider.address)
        ).to.be.revertedWith("Provider not approved")
    })

    it("should return data from DealProvider using LockedDealNFT", async () => {
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.deep.equal(dealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token])
        expect(poolData.params[0]).to.equal(amount)
    })

    it("should return data from LockDealProvider using LockedDealNFT", async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await lockDealProvider.createNewPool(receiver.address, token, [amount, startTime])
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.deep.equal(lockDealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token])
        expect(poolData.params[0]).to.equal(amount)
        expect(poolData.params[1]).to.equal(startTime)
    })

    it("should return data from TimedDealProvider using LockedDealNFT", async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await timedDealProvider.createNewPool(receiver.address, token, [amount, startTime, finishTime, amount])
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.deep.equal(timedDealProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token])
        expect(poolData.params[0]).to.equal(amount)
        expect(poolData.params[1]).to.equal(startTime)
        expect(poolData.params[2]).to.equal(finishTime)
        expect(poolData.params[3]).to.equal(amount)
    })

    it("should set baseURI", async () => {
        const baseURI = "https://poolz.finance/"
        await lockDealNFT.setBaseURI(baseURI)
        expect(await lockDealNFT.baseURI()).to.equal(baseURI)
    })

    it("should revert set baseURI for not owner", async () => {
        const baseURI = "https://notOwner.finance/"
        await expect(lockDealNFT.connect(notOwner).setBaseURI(baseURI)).to.be.revertedWith("Ownable: caller is not the owner")
    })

    it("should revert the same baseURI", async () => {
        const baseURI = await lockDealNFT.baseURI()
        await expect(lockDealNFT.setBaseURI(baseURI)).to.be.revertedWith("can't set the same baseURI")
    })

    it("should return tokenURI", async () => {
        const baseURI = await lockDealNFT.baseURI()
        expect(await lockDealNFT.tokenURI(poolId)).to.equal(baseURI + poolId.toString())
    })

    it("should return tokenURI event", async () => {
        const oldBaseURI = await lockDealNFT.baseURI()
        const baseURI = "https://nft.poolz.finance/test/metadata/"
        const tx = await lockDealNFT.setBaseURI(baseURI)
        await tx.wait()
        const events = await lockDealNFT.queryFilter(lockDealNFT.filters.BaseURIChanged())
        expect(events[events.length - 1].args.oldBaseURI).to.equal(oldBaseURI)
        expect(events[events.length - 1].args.newBaseURI).to.equal(baseURI)
    })
})
