import { expect, assert } from "chai";
import { constants } from "ethers";
import { ethers } from 'hardhat';
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { BaseLockDealProvider } from "../typechain-types/contracts/BaseProvider";
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT";
import { DealProvider } from "../typechain-types/contracts/DealProvider";
import { ERC20Token } from '../typechain-types/poolz-helper-v2/contracts/token';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Base Lock Deal Provider", function () {
    let baseLockProvider: BaseLockDealProvider 
    let dealProvider: DealProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let params: [number, number]
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let token: ERC20Token
    let startTime: number
    const amount = 10000

    before(async () => {
        ;[receiver, newOwner] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const DealProvider = await ethers.getContractFactory("DealProvider")
        const BaseLockProvider = await ethers.getContractFactory("BaseLockDealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        const MockVaultManager = await ethers.getContractFactory("MockVaultManager")
        const mockVaultManagger = await MockVaultManager.deploy()
        await mockVaultManagger.deployed()
        lockDealNFT = await LockDealNFT.deploy(mockVaultManagger.address)
        await lockDealNFT.deployed()
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        await dealProvider.deployed()
        baseLockProvider = await BaseLockProvider.deploy(lockDealNFT.address, dealProvider.address)
        await baseLockProvider.deployed()
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await token.deployed()
        await token.approve(baseLockProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManagger.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(baseLockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        let date = new Date()
        date.setDate(date.getDate())
        startTime = Math.floor(date.getTime() / 1000)
        params = [amount, startTime]
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await baseLockProvider.createNewPool(receiver.address, token.address, params)
    })

    it("should check deal provider address", async () => {
        const provider = await baseLockProvider.dealProvider()
        expect(provider.toString()).to.equal(dealProvider.address)
    })

    it("should check cascade pool creation events", async () => {
        const tx = await baseLockProvider.createNewPool(receiver.address, token.address, params)
        await tx.wait()
        const event = await dealProvider.queryFilter(dealProvider.filters.NewPoolCreated())
        expect(event[event.length - 1].args.poolInfo.poolId).to.equal(poolId + 1)
        expect(event[event.length - 1].args.poolInfo.token).to.equal(token.address)
        expect(event[event.length - 1].args.poolInfo.owner).to.equal(receiver.address)
        expect(event[event.length - 1].args.params[0]).to.equal(amount)
    })

    it("should get base provider data after creation", async () => {       
        const poolData = await baseLockProvider.getData(poolId);
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
        expect(poolData.params[0]).to.equal(amount);
        expect(poolData.params[1]).to.equal(startTime);
    })

    it("should revert zero owner address", async () => {
        await expect(
            baseLockProvider.createNewPool(receiver.address, constants.AddressZero, params)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert zero token address", async () => {
        await expect(baseLockProvider.createNewPool(constants.AddressZero, token.address, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero amount", async () => {
        const params = ["0", startTime]
        await expect(baseLockProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
            "amount should be greater than 0"
        )
    })

    describe("Base Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            
            const poolData = await baseLockProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
            expect(poolData.params[1]).to.equal(startTime);
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)

            const poolData = await baseLockProvider.getData(poolId + 1);
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, newOwner.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
            expect(poolData.params[1]).to.equal(startTime);
        })
    })

    describe("Base Deal Withdraw", () => {
        it("should withdraw tokens", async () => {
            await time.increase(3600)
            await lockDealNFT.withdraw(poolId)
            
            const poolData = await baseLockProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, constants.AddressZero, token.address]);
            expect(poolData.params[0]).to.equal(0);
            expect(poolData.params[1]).to.equal(startTime);
        })
    })
})
