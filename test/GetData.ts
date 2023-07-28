import { expect } from "chai"
import { constants } from "ethers"
import { ethers } from 'hardhat'
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { LockDealProvider } from "../typechain-types"
import { LockDealNFT } from "../typechain-types"
import { DealProvider } from "../typechain-types"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { deployed, token, BUSD } from "./helper"
import { MockVaultManager } from "../typechain-types"


describe("Data tests", function () {
    let lockProvider: LockDealProvider 
    let dealProvider: DealProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let dealReceiver: SignerWithAddress
    let lockReceiver: SignerWithAddress
    let startTime: number
    const amount = 10000

    before(async () => {
        [dealReceiver, lockReceiver] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address, "")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    describe("Get DealProvider Data", async () => {
        let params: [number]
        before(async () => {
            poolId = (await lockDealNFT.totalSupply()).toNumber()
            params = [amount]
            await dealProvider.createNewPool(dealReceiver.address, token, params)
            await dealProvider.createNewPool(dealReceiver.address, BUSD, params)
        })

        it("should get user data by tokens", async () => {
            const poolData = await lockDealNFT.getUserDataByTokens(dealReceiver.address, [token, BUSD], 0, 1)
            expect(poolData[0]).to.deep.equal([dealProvider.address, poolId, dealReceiver.address, token, params])
            expect(poolData[1]).to.deep.equal([dealProvider.address, poolId + 1, dealReceiver.address, BUSD, params])
        })
    })

    describe("Get LockProvider Data", async () => {
        let params: [number, number]

        before(async () => {
            startTime = await time.latest() + 100
            params = [amount, startTime]
            poolId = (await lockDealNFT.totalSupply()).toNumber()
            await lockProvider.createNewPool(lockReceiver.address, token, params)
            await lockProvider.createNewPool(lockReceiver.address, BUSD, params)
        })

        it("should get user data by tokens", async () => {
            const poolData = await lockDealNFT.getUserDataByTokens(lockReceiver.address, [token, BUSD], 0, 1)
            expect(poolData[0]).to.deep.equal([lockProvider.address, poolId, lockReceiver.address, token, params])
            expect(poolData[1]).to.deep.equal([lockProvider.address, poolId + 1, lockReceiver.address, BUSD, params])
        })
    })
})
