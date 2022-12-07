const holders = require("./holders.json")
const ignoreList = ["0x1118cD6dFdD8D34f5b4ed41e2A378553f60448bd",
"0x1aE86dFdEEf0CFab18Ed0F3b43F8C9Ea26F2C156",
"0x000000000000000000000000000000000000dEaD",
"0xc4D75E14Fe19Da160d09Cf6203c4F625B42663f3",
""


]
const batchSize = 100
const subBatchCount = 1
const gville = "0x7c22E823b5eE641ed534CE3e368b59b5F0A3b7e0" 
const migratorAddress = "0xDe2a42e378E356F3A7e77215d686ec4eaE2552DE"
const {ethers} = hre
const lastBlock = 23341571

async function main() {

    const migrator = await ethers.getContractAt("Migrator", migratorAddress)



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
            return fart.addr != ethers.constants.AddressZero && !ignoreList.includes(fart.addr) && fart.amount != "0"
        }))
        await Promise.all(fixed.map(async tx => {
            if (tx.length > 0) {
                let success = false
                while(!success) {
                    try {
                        await (await migrator.migrateMultiple(tx)).wait()
                        success = true
                    } catch(e) {console.log(`retrying failed tx with error: ${e}`)}
                }
            }
        }))
    }

}

main()
