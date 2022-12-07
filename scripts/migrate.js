const holders = require("./holders.json")
const ignoreList = [0x1118cD6dFdD8D34f5b4ed41e2A378553f60448bd,
0x1aE86dFdEEf0CFab18Ed0F3b43F8C9Ea26F2C156,
0x000000000000000000000000000000000000dEaD,
0xc4D75E14Fe19Da160d09Cf6203c4F625B42663f3]
const batchSize = 100
const subBatchCount = 1
const gville = "0x9A2748FfD2923155b7C726EbdaCC11A1c2d3BF68" 
const {ethers} = hre

async function main() {

    const Migrator = await ethers.getContractFactory("Migrator")
    const migrator = await (await Migrator.deploy(gville)).deployed()
    await (await migrator.grantRole(await migrator.MIGRATOR_ROLE(), await (await ethers.getSigner()).getAddress())).wait() 
    const gvilleContract = await ethers.getContractAt("Token", gville)
    await (await gvilleContract.grantRole(await gvilleContract.TOKEN_MAESTRO_ROLE(), migrator.address)).wait() 

    for(let i = 0; i < holders.length; i += batchSize) {
        const end = i + batchSize - 1
        console.log(`processing holders ${i} to ${end}`)
        const batch = holders.slice(i, end)
        const subBatchSize = Math.ceil(batchSize / subBatchCount)
        const subBatches = []
        for(let j = 0; j < batch.length; j += subBatchSize) {
            subBatches.push(batch.slice(j, j + subBatchSize - 1))
        }
        const fixed = subBatches.map( el => el.map(ass => ({addr: ass.address, amount: ass.balance})).filter(fart => {
            return fart.addr != ethers.constants.AddressZero || ignoreList.includes(fart.addr)
        }))
        await Promise.all(fixed.map(async tx => await (await migrator.migrateMultiple(tx)).wait()))
    }

}

main()
