const { ethers } = require("hardhat")

const deployed = async (contractName, ...args) => {
    const Contract = await ethers.getContractFactory(contractName)
    const contract = await Contract.deploy(...args)
    return contract.deployed()
}

module.exports = { deployed }