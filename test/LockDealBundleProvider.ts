import { expect, } from "chai";
import { BigNumber, constants } from "ethers";
import { ethers } from 'hardhat';
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { LockDealProvider } from "../typechain-types/contracts/LockProvider";
import { TimedDealProvider } from "../typechain-types/contracts/TimedDealProvider";
import { LockDealBundleProvider } from "../typechain-types/";
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT";
import { DealProvider } from "../typechain-types/contracts/DealProvider";
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockProvider } from "../typechain-types/contracts/test/MockProvider";
import { deployed } from "./helper";
import { MockVaultManager } from "../typechain-types";

describe("Lock Deal Bundle Provider", function () {
    let bundleProvider: LockDealBundleProvider
    let timedDealProvider: TimedDealProvider 
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
    let lockDealNFT: LockDealNFT
    let mockProvider: MockProvider
    let poolId: number
    let bundlePoolId: number
    let receiver: SignerWithAddress
    let token: ERC20Token
    let startTime: number, finishTime: number
    const amount = BigNumber.from(100000)
    const ONE_DAY = 86400

    before(async () => {
        [receiver] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedDealProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
        bundleProvider = await deployed("LockDealBundleProvider", lockDealNFT.address)
        mockProvider = await deployed("MockProvider", timedDealProvider.address)
        await token.approve(mockVaultManager.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedDealProvider.address, true)
        await lockDealNFT.setApprovedProvider(bundleProvider.address, true)
        await lockDealNFT.setApprovedProvider(mockProvider.address, true)
    })

    beforeEach(async () => {
        startTime = await time.latest() + ONE_DAY   // plus 1 day
        finishTime = startTime + 7 * ONE_DAY   // plus 7 days from `startTime`
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams, timedDealProviderParams]
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await bundleProvider.createNewPool(receiver.address, token.address, bundleProviders, bundleProviderParams)
        bundlePoolId = (await lockDealNFT.totalSupply()).toNumber() - 1
    })

    it("should check lock deal NFT address", async () => {
        const nftAddress = await bundleProvider.lockDealNFT()
        expect(nftAddress.toString()).to.equal(lockDealNFT.address)
    })

    it("should get bundle provider data after creation", async () => {
        const poolData = await bundleProvider.getData(bundlePoolId);

        // check the pool data
        expect(poolData.poolInfo).to.deep.equal([bundlePoolId, receiver.address, constants.AddressZero]);
        expect(poolData.params[0]).to.equal(poolId);

        // check the NFT ownership
        expect(await lockDealNFT.ownerOf(poolId)).to.equal(bundleProvider.address);
        expect(await lockDealNFT.ownerOf(poolId + 1)).to.equal(bundleProvider.address);
        expect(await lockDealNFT.ownerOf(poolId + 2)).to.equal(bundleProvider.address);
        expect(await lockDealNFT.ownerOf(bundlePoolId)).to.equal(receiver.address);
    })

    it("should check cascade NewPoolCreated event", async () => {
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams, timedDealProviderParams]

        const tx = await bundleProvider.createNewPool(receiver.address, token.address, bundleProviders, bundleProviderParams)
        await tx.wait()
        const event = await dealProvider.queryFilter(dealProvider.filters.NewPoolCreated())
        const data = event[event.length - 1].args
        const bundlePoolId = (await lockDealNFT.totalSupply()).toNumber() - 1;

        expect(data.poolInfo.poolId).to.equal(bundlePoolId - 1)
        expect(data.poolInfo.token).to.equal(token.address)
        expect(data.poolInfo.owner).to.equal(bundleProvider.address)
        expect(data.params[0]).to.equal(amount)
    })

    it("should revert invalid provider address", async () => {
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams, timedDealProviderParams]

        // zero address
        bundleProviders[0] = constants.AddressZero
        await expect(
            bundleProvider.createNewPool(receiver.address, token.address, bundleProviders, bundleProviderParams)
        ).to.be.revertedWith("invalid provider address")

        // lockDealNFT address
        bundleProviders[0] = lockDealNFT.address
        await expect(
            bundleProvider.createNewPool(receiver.address, token.address, bundleProviders, bundleProviderParams)
        ).to.be.revertedWith("invalid provider address")

        // bundleProvider address
        bundleProviders[0] = bundleProvider.address
        await expect(
            bundleProvider.createNewPool(receiver.address, token.address, bundleProviders, bundleProviderParams)
        ).to.be.reverted
    })

    it("should revert zero token address", async () => {
        const dealProviderParams = [amount]
        const lockProviderParams = [amount, startTime]
        const timedDealProviderParams = [amount, startTime, finishTime, amount]
        const bundleProviders = [dealProvider.address, lockProvider.address, timedDealProvider.address]
        const bundleProviderParams = [dealProviderParams, lockProviderParams, timedDealProviderParams]

        await expect(bundleProvider.createNewPool(receiver.address, constants.AddressZero, bundleProviders, bundleProviderParams)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    describe("Lock Deal Bundle Withdraw", () => {
        it("should withdraw all tokens before the startTime", async () => {
            await time.increaseTo(startTime - 1)
            const withdrawnAmount = (await lockDealNFT.callStatic.withdraw(bundlePoolId)).withdrawnAmount
            expect(withdrawnAmount).to.equal(amount)    // from DealProvider
        })

        it("should withdraw all tokens from bundle at the startTime", async () => {
            await time.increaseTo(startTime)
            const withdrawnAmount = (await lockDealNFT.callStatic.withdraw(bundlePoolId)).withdrawnAmount
            expect(withdrawnAmount).to.equal(amount.mul(2)) // from DealProvider + LockDealProvider
        })

        it("should withdraw all tokens from bundle at the startTime + 1 day", async () => {
            await time.increaseTo(startTime + ONE_DAY)
            const withdrawnAmount = (await lockDealNFT.callStatic.withdraw(bundlePoolId)).withdrawnAmount
            expect(withdrawnAmount).to.equal(BigNumber.from(amount.mul(2)).add(amount.div(7)))  // from DealProvider + LockDealProvider
        })

        it("should withdraw all tokens after the finishTime", async () => {
            await time.increaseTo(finishTime)
            const withdrawnAmount = (await lockDealNFT.callStatic.withdraw(bundlePoolId)).withdrawnAmount
            expect(withdrawnAmount).to.equal(amount.mul(3)) // from DealProvider + LockDealProvider + TimedDealProvider
        })

        it("should revert if not called from the lockDealNFT contract", async () => {
            await expect(bundleProvider.withdraw(100)).to.be.revertedWith("only NFT contract can call this function")
        })
    })
})
