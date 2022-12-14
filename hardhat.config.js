require("@nomicfoundation/hardhat-toolbox");
const fs = require("fs")
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.17"
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
