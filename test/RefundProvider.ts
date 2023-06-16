import { MockVaultManager } from "../typechain-types"
import { DealProvider, IDealProvierEvents } from "../typechain-types/contracts/DealProvider"
import { LockDealNFT } from "../typechain-types/contracts/LockDealNFT"
import { RefundProvider } from "../typechain-types/contracts/RefundProvider/RefundProvider.sol"
import { ERC20Token } from "../typechain-types/poolz-helper-v2/contracts/token"
import { deployed } from "./helper"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { constants, BigNumber } from "ethers"

describe("Refund Provider", function () {
    let dealProvider: DealProvider
    let refundProvider: RefundProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let token: ERC20Token
    let BUSD: ERC20Token
    let params: [number, number, number]
    let poolData: [IDealProvierEvents.BasePoolInfoStructOutput, BigNumber[]] & {
        poolInfo: IDealProvierEvents.BasePoolInfoStructOutput
        params: BigNumber[]
    }
    const amount = 10000

    before(async () => {
        [receiver, newOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        BUSD = await deployed("ERC20Token", "BUSD Token", "BUSD")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        refundProvider = await deployed("RefundProvider", lockDealNFT.address, dealProvider.address)
        await token.approve(mockVaultManager.address, constants.MaxUint256)
        await BUSD.approve(mockVaultManager.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(refundProvider.address, true)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
    })

    beforeEach(async () => {
        // poolId = (await lockDealNFT.totalSupply()).toNumber()
         params = [amount, amount, amount]
        // const rate = 2
        // await refundProvider.createNewRefundPool(token.address, receiver.address, BUSD.address, rate, params)
    })

    it("should create single refund pool", async () => {
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await refundProvider.createNewRefundPool(token.address, receiver.address, BUSD.address, dealProvider.address, params)
    })
})
