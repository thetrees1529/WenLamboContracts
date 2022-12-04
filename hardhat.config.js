require("@nomicfoundation/hardhat-toolbox");
const fs = require("fs")
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
}
if(fs.existsSync("./privateKey.json")) {
  module.exports.networks = {
    fuji: {
      url: "https://rpc.ankr.com/avalanche_fuji",
      accounts: [require("./privateKey.json")]
    }
  }
}
