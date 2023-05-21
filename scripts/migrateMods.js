const stats = require("./modStats.json")

const  {ethers} = hre

const contractAddress = "0x7585513DF66C3B379709Bba6D4a5f84519DA019f"

const startAt = 0
const batchSize = 500

async function main() {
    const mods = await ethers.getContractAt("Mods", contractAddress)
    for(let i = startAt; i < stats.length; i += batchSize) {
        console.log(`doing batch ${i} to ${Math.min(i + batchSize, stats.length)}`)
        const batch = stats.slice(i, i + batchSize)
        const tx = await mods.manualIncrease(batch)
        await tx.wait()
    }
}

main()