const {ethers} = hre
const chain = "https://rpc.ankr.com/harmony"
const fs = require("fs")
const chunkSize = 1024
const batchSize = 1000
const lookingFor = 5747
// const addr = "0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a"
const addr = "0x3CB937CB5d4c6f8a158ACF3B6f6569a7AA07dbF0"
const deployedAt = 34639913
const saveTo = `${__dirname}/result.json`
const abi = [
    "event Listed(uint listingId, address seller, uint tokenId, uint price, uint expiresAt)",
    "event Transfer(address from, address to, uint value)",
    "event Cancelled(uint listingId)"
]

async function main() {
    const contract = new ethers.Contract(addr, abi, new ethers.providers.JsonRpcProvider(chain))
    const intervals = []
    const lastBlock = (await contract.provider.getBlock()).number
    console.log(lastBlock)
    for(let i = deployedAt; i < lastBlock; i += chunkSize) {
        intervals.push({
            start: i,
            end: i + chunkSize
        })
    }

    const batches = []
    for(let i = 0; i < intervals.length; i += batchSize) {
        batches.push(intervals.slice(i, i + batchSize))
    }

    fs.writeFileSync(saveTo, JSON.stringify([]), "utf-8")

    for(let i = 0; i < batches.length; i ++) {
        await Promise.all(batches[i].map(
            async interval => {
                console.log(`checking ${JSON.stringify(interval)}`)
                let succ = false
                let events
                while(!succ) {
                    try {
                        events = await contract.queryFilter("*", interval.start, interval.end)
                        console.log(events)
                        succ = true
                    } catch(e) {
                        console.error(e)
                    }
                }
                    const result = JSON.parse(fs.readFileSync(saveTo))
                    result.push(events.map(event => ({topics: event.topics, event:event.event})))
                    fs.writeFileSync(saveTo, JSON.stringify(result), "utf-8")
                
            }
        ))
    }

    
    
}

main()