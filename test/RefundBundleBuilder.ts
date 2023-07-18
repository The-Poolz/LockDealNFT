import { MockVaultManager } from "../typechain-types"
import { CollateralProvider } from "../typechain-types"
import { DealProvider } from "../typechain-types"
import { LockDealNFT } from "../typechain-types"
import { LockDealProvider } from "../typechain-types"
import { RefundProvider } from "../typechain-types"
import { TimedDealProvider } from "../typechain-types"
import { RefundBundleBuilder } from "../typechain-types/"
import { LockDealBundleProvider } from "../typechain-types/"
import { deployed, token, BUSD } from "./helper"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { BigNumber } from "ethers"
import { ethers } from "hardhat"

describe("Builder", function () {
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider
    let refundProvider: RefundProvider
    let timedProvider: TimedDealProvider
    let collateralProvider: CollateralProvider
    let bundleProvider: LockDealBundleProvider
    let bundleBuilder: RefundBundleBuilder
    let halfTime: number
    let lockDealNFT: LockDealNFT
    let poolId: number
    let userSplits: [{ user: string; amount: string; }, { user: string; amount: string; }, { user: string; amount: string; }, { user: string; amount: string; }]
    let addressParams: [string, string, string, string]
    let user1: SignerWithAddress
    let user2: SignerWithAddress
    let user3: SignerWithAddress
    let projectOwner: SignerWithAddress
    let params: [(number | BigNumber)[], (string | number)[], (string | number)[]]
    let startTime: number, finishTime: number
    const mainCoinAmount = ethers.utils.parseEther("30")
    const amount = ethers.utils.parseEther("100").toString()
    const ONE_DAY = 86400

    before(async () => {
        ;[user1, user2, user3, projectOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
        collateralProvider = await deployed("CollateralProvider", lockDealNFT.address, dealProvider.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, collateralProvider.address)
        bundleProvider = await deployed("LockDealBundleProvider", lockDealNFT.address)
        bundleBuilder = await deployed(
            "RefundBundleBuilder",
            lockDealNFT.address,
            refundProvider.address,
            bundleProvider.address,
            collateralProvider.address
        )
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedProvider.address, true)
        await lockDealNFT.setApprovedProvider(collateralProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockDealNFT.address, true)
        await lockDealNFT.setApprovedProvider(bundleProvider.address, true)
        await lockDealNFT.setApprovedProvider(bundleBuilder.address, true)
    })

    beforeEach(async () => {
        poolId = (await lockDealNFT.tokenIdCounter()).toNumber()
        userSplits = [
            { user: user1.address, amount: amount },
            { user: user2.address, amount: amount },
            { user: user3.address, amount: amount },
            { user: user3.address, amount: amount }
        ]
        addressParams = [token, BUSD, timedProvider.address, lockProvider.address]
        startTime = (await time.latest()) + ONE_DAY // plus 1 day
        finishTime = startTime + 7 * ONE_DAY // plus 7 days from `startTime`
        const paramsAmount = ethers.utils.parseEther("200").toString()
        params = [[mainCoinAmount, finishTime], [paramsAmount, startTime, finishTime], [paramsAmount, startTime]]
        await bundleBuilder.connect(projectOwner).buildRefundBundle(userSplits, addressParams, params)
    })

    it("should check collateral data after builder creation", async () => {
        const poolData = await lockDealNFT.getData(poolId)
        expect(poolData.provider).to.equal(collateralProvider.address)
        expect(poolData.poolInfo).to.deep.equal([poolId, projectOwner.address, BUSD])
        expect(poolData.params[0]).to.equal(mainCoinAmount)
        expect(poolData.params[1]).to.equal(finishTime)
    })

    // it("should check users refund token data after builder creation", async () => {
    //     // poolId = (await lockDealNFT.tokenIdCounter()).toNumber() - 1
    //     // const length = poolId - userSplits.length * 2
    //     // let j = addressParams.length - 1
    //     // let k = 0
    //     // for(let i = poolId; i > length; i -= 2) {
    //     //     const userData = await lockDealNFT.getData(i)
    //     //     //console.log(userData.provider);
    //     //     // console.log(i)
    //     //     // console.log(dealProvider.address)
    //     //     // console.log(lockProvider.address)
    //     //     // console.log(timedProvider.address)
    //     //     // console.log("refundProvider", refundProvider.address)
    //     //     // console.log("collateralProvider", collateralProvider.address)
    //     //     // console.log("lockDealNFT", lockDealNFT.address)
    //     //     // console.log("bundleProvider", bundleProvider.address)
    //     //     // console.log("bundleBuilder", bundleBuilder.address)
    //     //     // console.log("UserData", userData.provider)
    //     //     //console.log("addressParams", addressParams[j])
    //     //     expect(userData.provider).to.equal(dealProvider.address)
    //     //     //expect(userData.poolInfo).to.deep.equal([poolId, userSplits[k++].user, token])
    //     // }
    // })
})
