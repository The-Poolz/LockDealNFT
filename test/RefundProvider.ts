import { MockVaultManager } from "../typechain-types"
import { DealProvider, IDealProvierEvents } from "../typechain-types/contracts/DealProvider"
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT"
import { LockDealProvider } from "../typechain-types/contracts/LockProvider";
import { RefundProvider } from "../typechain-types/contracts/RefundProvider/RefundProvider.sol"
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ERC20Token } from "../typechain-types/poolz-helper-v2/contracts/token"
import { deployed } from "./helper"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { constants, BigNumber } from "ethers"

describe("Refund Provider", function () {
    let lockProvider: LockDealProvider
    let dealProvider: DealProvider 
    let refundProvider: RefundProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let token: ERC20Token
    let BUSD: ERC20Token
    let params: [number, number, number, number]
    let startTime: number
    // let poolData: [IDealProvierEvents.BasePoolInfoStructOutput, BigNumber[]] & {
    //     poolInfo: IDealProvierEvents.BasePoolInfoStructOutput
    //     params: BigNumber[]
    // }
    const amount = 10000

    before(async () => {
        [receiver, newOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        BUSD = await deployed("ERC20Token", "BUSD Token", "BUSD")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, lockProvider.address)
        await token.approve(mockVaultManager.address, constants.MaxUint256)
        await BUSD.approve(mockVaultManager.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
    })

    beforeEach(async () => {
        startTime = await time.latest()
        params = [amount, startTime, amount, startTime]
        await refundProvider.createNewRefundPool(
            token.address,
            receiver.address,
            BUSD.address,
            lockProvider.address,
            params
        )
        poolId = (await lockDealNFT.totalSupply()).toNumber() - 1
    })

    it("should split pool to half", async () => {
        await lockDealNFT.split(poolId, amount / 2, receiver.address)
        poolId = (await lockDealNFT.totalSupply()).toNumber() - 1
        // const poolData = await refundProvider.getData(poolId)
        // expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, BUSD.address]);
        // expect(poolData.params[0]).to.equal(amount / 2);
        // expect(poolData.params[1]).to.equal(0);
    })
})
