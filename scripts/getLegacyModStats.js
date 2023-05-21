const { ethers } = hre;
const path = require("path")
const harmony = new ethers.providers.JsonRpcProvider("https://api.harmony.one");
const abi = (require("../artifacts/contracts/Legacy/Lambo.sol/Lambos.json")).abi
const contractAddress = "0x728523c45fab916c4a4b3b8ba60e631555f89e9e"
const fs = require("fs").promises
const start = 0
const end = 10000
const batchSize = 1000
let lambos
async function main() {
    lambos = new ethers.Contract(contractAddress, abi, harmony)
    let results = []
    for(let i = start; i < end; i += batchSize) {
        console.log(`doing batch ${i} to ${Math.min(i + batchSize, end)}`)
        const res = (await getBatch(i, Math.min(i + batchSize, end)))
        res.forEach(async (el,index) => {
            results = results.concat(Object.keys(el).map(key => [i + index, el[key].statistic, el[key].value.toString()]))
        })
    }
    await fs.writeFile(path.resolve(__dirname, "modStats.json"), JSON.stringify(results))
}

function getBatch(start, end) {
    
    const length = end - start
    const inputs = new Array(length).fill(0).map((_, i) => start + i)
    return Promise.all(inputs.map(el => tryTilWorks(lambos.getAttributes,el)))
}

async function tryTilWorks(f, ...args) {
    let res
    while(!res) {
        try {
            res = await f(...args)
        } catch{
            console.log("failed, trying again")
        }
    }
    return res
}

main()