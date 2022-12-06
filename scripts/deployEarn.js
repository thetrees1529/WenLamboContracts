const { ethers } = hre

const {
    burnRatio,
nft,
 tokenAddr ,
 lockDelay ,
 lockPeriod , 
 lockRatio , 
 interest , 
 baseEarn , 
 mintCap ,
 stages: config
} = require("./earnConfigs.js")["fujiMuscle"]

async function main() {
    const token = await ethers.getContractAt("Token", tokenAddr)
    const Contract = await ethers.getContractFactory("Earn")
    const unlockStart = Math.round(Date.now() / 1000 + lockDelay)
    const contract = await (await Contract.deploy(
        nft,
        tokenAddr,
        config,
        lockRatio,
        burnRatio,
        interest,
        unlockStart,
        unlockStart + lockPeriod,
        baseEarn,
        mintCap
    )).deployed()
    await (await token.grantRole(await token.TOKEN_MAESTRO_ROLE(), contract.address)).wait()
    console.log(contract.address)
}

main()

