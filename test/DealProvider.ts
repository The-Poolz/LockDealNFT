import { expect } from "chai";
import { constants, BigNumber } from "ethers";
import { ethers } from 'hardhat';
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT";
import { DealProvider } from "../typechain-types/contracts/DealProvider";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockVaultManager } from "../typechain-types";
import { deployed, token } from "./helper";

describe("Deal Provider", function () {
    let dealProvider: DealProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let params: [number]
    let poolData: [IDealProvierEvents.BasePoolInfoStructOutput, BigNumber[]] & {
        poolInfo: IDealProvierEvents.BasePoolInfoStructOutput;
        params: BigNumber[];
    }
    const amount = 10000

    before(async () => {
        [receiver, newOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        params = [amount]
        await dealProvider.createNewPool(receiver.address, token, params)
    })

    it("should get pool data", async () => {
        poolData = await dealProvider.getData(poolId);
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token]);
        expect(poolData.params[0]).to.equal(amount);
    })

    it("should check pool creation events", async () => {
        const tx = await dealProvider.createNewPool(receiver.address, token, params)
        await tx.wait()
        const events = await dealProvider.queryFilter(dealProvider.filters.NewPoolCreated())
        expect(events[events.length - 1].args.poolId).to.equal(poolId + 1)
        expect(events[events.length - 1].args.token).to.equal(token)
        expect(events[events.length - 1].args.owner).to.equal(receiver.address)
        expect(events[events.length - 1].args.params[0]).to.equal(amount) //assuming amount is at index 0 in the params array
    })

    it("should revert zero owner address", async () => {
        await expect(dealProvider.createNewPool(receiver.address, constants.AddressZero, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero token address", async () => {
        await expect(dealProvider.createNewPool(constants.AddressZero, token, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero params", async () => {
        await expect(dealProvider.createNewPool(receiver.address, token, [])).to.be.revertedWith(
            "invalid params length"
        )
    })

    describe("Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)

            poolData = await dealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token]);
            expect(poolData.params[0]).to.equal(amount / 2);
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)

            poolData = await dealProvider.getData(poolId + 1);
            expect(poolData.poolInfo).to.deep.equal([poolId + 1, newOwner.address, token]);
            expect(poolData.params[0]).to.equal(amount / 2);
        })
    })

    describe("Deal Withdraw", () => {
        it("should return withdrawAmount and isFinal values", async () => {
            const [withdrawnAmount, isFinal] = await lockDealNFT.callStatic.withdraw(poolId)
            expect(withdrawnAmount.toString()).to.equal(amount.toString())
            expect(isFinal).to.equal(true)
        })

        it("should check data in pool after withdraw", async () => {
            await lockDealNFT.withdraw(poolId)
            
            poolData = await dealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, constants.AddressZero, token]);
            expect(poolData.params[0]).to.equal(0);
        })

        it("should check events after withdraw", async () => {
            poolId = (await lockDealNFT.totalSupply()).toNumber()
            const tx = await lockDealNFT.withdraw(poolId)
            await tx.wait()
            const events = await dealProvider.queryFilter(dealProvider.filters.TokenWithdrawn())
            expect(events[events.length - 1].args.poolId.toString()).to.equal(poolId.toString())
            expect(events[events.length - 1].args.owner.toString()).to.equal(receiver.address.toString())
            expect(events[events.length - 1].args.withdrawnAmount.toString()).to.equal(amount.toString())
            expect(events[events.length - 1].args.leftAmount.toString()).to.equal("0".toString())
        })
    })
})
