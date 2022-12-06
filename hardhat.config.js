require("@nomicfoundation/hardhat-toolbox");
const fs = require("fs")
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: fs.existsSync("./privateKey.json") ? {
    fuji: {
      url: "https://rpc.ankr.com/avalanche_fuji",
      accounts: [require("./privateKey.json")]
    },
    harmony: {
      url: "https://api.harmony.one",
      accounts: [require("./privateKey.json")]
    }
  } : undefined
}
