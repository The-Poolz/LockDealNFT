import { expect } from "chai";
import { ethers } from 'hardhat';
import { LockDealNFT } from "../typechain-types";
import { DealProvider } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockVaultManager } from "../typechain-types";
import { deployed, token, BUSD } from "./helper";

describe("Data tests", function () {
    let dealProvider: DealProvider
    let lockDealNFT: LockDealNFT
    let poolId: number
    let receiver: SignerWithAddress
    let newOwner: SignerWithAddress
    let params: [number]
    const amount = 10000

    before(async () => {
        [receiver, newOwner] = await ethers.getSigners()
        const mockVaultManager: MockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address, "")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        params = [amount]
        await dealProvider.createNewPool(receiver.address, token, params)
        await dealProvider.createNewPool(receiver.address, BUSD, params)
    })

    describe("Get DealProvider Data", async () => {
        it("should get user data by tokens", async () => {
            const poolData = await lockDealNFT.getUserDataByTokens(receiver.address, [token, BUSD])
            expect(poolData[0]).to.deep.equal([dealProvider.address, poolId, receiver.address, token, params])
            expect(poolData[1]).to.deep.equal([dealProvider.address, poolId + 1, receiver.address, BUSD, params])
        })
    })
})
