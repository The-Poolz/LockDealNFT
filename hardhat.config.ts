import { HardhatUserConfig } from "hardhat/config";
import 'hardhat-gas-reporter';
import '@typechain/hardhat';
import 'solidity-coverage';
import '@nomicfoundation/hardhat-network-helpers';
import '@nomicfoundation/hardhat-chai-matchers';
import "@truffle/dashboard-hardhat-plugin"

require("dotenv").config();

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    compilers: [
      {
        version: '0.8.25',
        settings: {
          evmVersion: 'istanbul',
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      blockGasLimit: 130_000_000,
    },
    ropsten: {
      url: 'https://ropsten.infura.io/v3/your-infura-project-id',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/your-infura-project-id',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    kovan: {
      url: 'https://kovan.infura.io/v3/your-infura-project-id',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    goerli: {
      url: 'https://goerli.infura.io/v3/your-infura-project-id',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    bsc_testnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      accounts: [], // Replace with your testnet accounts' private keys
    },
    polygon_mumbai: {
      url: 'https://rpc-mumbai.matic.today',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    fantom_testnet: {
      url: 'https://rpc.testnet.fantom.network',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    avalanche_fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    harmony_testnet: {
      url: 'https://api.s0.b.hmny.io',
      accounts: [], // Replace with your testnet accounts' private keys
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/your-infura-project-id',
      accounts: [], // Replace with your mainnet accounts' private keys
    },
  },
  gasReporter: {
    enabled: true,
    showMethodSig: true,
    currency: 'USD',
    token: 'BNB',
    gasPriceApi: 'https://api.bscscan.com/api?module=proxy&action=eth_gasPrice&apikey=' + process.env.BSCSCAN_API_KEY,
    coinmarketcap: process.env.CMC_API_KEY || '',
    noColors: true,
    reportFormat: "markdown",
    outputFile: "gasReport.md",
    forceTerminalOutput: true,
    L1: "binance",
    forceTerminalOutputFormat: "terminal"
  },
};

export default config;
