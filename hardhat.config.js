const fs = require("fs");
require("@nomicfoundation/hardhat-toolbox");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200
          }
        },

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
      url: "https://rpc.ankr.com/avalanche",
      accounts: [require("./privateKey.json")]
    }
  } : undefined
}
