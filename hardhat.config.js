const fs = require("fs");
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {

    overrides: {
      "contracts/Legacy/Lambo.sol": {
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 1
          }
        },
        version: "0.8.19"
      },
      "contracts/Rewards/Earn2.sol": {
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 1
          }
        },
        version: "0.8.19"
      },
      "contracts/Migrating/ModsMigration.sol": {
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 1
          }
        },
        version: "0.8.19"
      },
      "contracts/Game/Mods2.sol": {
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 1
          }
        },
        version: "0.8.19"
      },
      "contracts/Nfts/Toolboxes2.sol": {
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 1
          }
        },
        version: "0.8.19"
      }
    },
    compilers: [
      {
        version: "0.8.19"
      },
      {
        version: "0.8.15"
      }
    ]
  },
  networks: fs.existsSync("./privateKey.json") ? {
    fuji: {
      url: "https://rpc.ankr.com/avalanche_fuji",
      accounts: [require("./privateKey.json")]
    },
    harmony: {
      url: "https://api.harmony.one",
      accounts: [require("./privateKey.json")]
    },
    avax: {
      url: "https://avalanche.drpc.org",
      accounts: [require("./privateKey.json")]
    }
  } : undefined,
  etherscan: {
    apiKey: {
      avax: "e",
      fuji: "e"
    },
    customChains: [
      {
        network: "fuji",
        chainId: 43113,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://avalanche.testnet.routescan.io"
        }
      }
    ]
  } 
}
