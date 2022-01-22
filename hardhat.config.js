require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");

const ethReporterOptions = {
  coinmarketcap: "aacaaddd-219a-402e-964a-b80ad33190af",
  currency: "USD",
  token: "ETH",
  gasPrice: 70,
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.8.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1e6,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
    },
  },
  gasReporter: ethReporterOptions,
  paths: {
    sources: "./eth/contracts",
    tests: "./eth/test",
  },
};
