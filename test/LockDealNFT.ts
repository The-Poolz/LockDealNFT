import { expect } from "chai";
import { constants } from "ethers";
import { ethers } from 'hardhat';
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT";
import { DealProvider } from "../typechain-types/contracts/DealProvider";
import { LockDealProvider } from "../typechain-types/contracts/LockProvider";
import { TimedDealProvider } from "../typechain-types/contracts/TimedDealProvider";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockVaultManager } from "../typechain-types/contracts/test/MockVaultManager";
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
        [notOwner, receiver] = await ethers.getSigners()
        mockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
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

    it("should return mintInitiated event", async () => {
        const tx = await dealProvider.createNewPool(receiver.address, token, [amount])
        await tx.wait()
        const events = await lockDealNFT.queryFilter(lockDealNFT.filters.MintInitiated())
        expect(events[events.length - 1].args.provider).to.equal(dealProvider.address)
    })

    it("should save provider address", async () => {
        expect(await lockDealNFT.poolIdToProvider(poolId)).to.equal(dealProvider.address)
    })

    it("only provider can mint", async () => {
        await expect(
            lockDealNFT.connect(notOwner).mint(receiver.address, notOwner.address, token, 10, dealProvider.address)
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
})
