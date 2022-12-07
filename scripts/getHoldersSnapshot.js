const {ethers} = hre
const tokenAddr = "0xF9565E8c4E13862f677F144B3cdC8700D9c4BA31"
const deployedAt = 22899567
const saveTo = "holders.json"
const fs = require("fs").promises
const path = require("path")
const interval = 1024
const batchSize = 200

let token

async function main() {

    const holders = new Set()
    token = await ethers.getContractAt("IERC20", tokenAddr)

    const lastBlock = (await ethers.provider.getBlock()).number;

    const range = lastBlock - deployedAt
    const sections = Math.ceil(range / interval)

    let queue = Array.from(Array(sections).keys())
    queue = queue.map(item => {
        const start = deployedAt + item * interval
        const end = start + interval - 1
        return {
            start,
            end
        }
    })

    for(let i = 0; i < queue.length; i += batchSize) {
        const toProcess = queue.slice(i, i + batchSize - 1)
        await Promise.all(toProcess.map(async item => {
            console.log(`scanning ${item.start} to ${item.end}`)
            const range = await getRange(item.start, item.end)
            let newCount = 0
            range.forEach(log => {
                const args = log.args
                if(!holders.has(args.from)) {
                    holders.add(args.from)
                    newCount ++
                }
                if(!holders.has(args.to)) {
                    holders.add(args.to)
                    newCount ++
                }
            })
            console.log(`found ${newCount} more addresses`)
        }))

    }

    let balances = Array.from(holders.keys())
    const wallets = []

    for(let i = 0; i < balances.length; i += batchSize) {
        const toProcess = balances.slice(i, i + batchSize - 1)
        await Promise.all(toProcess.map(async item => {
            if(item === ethers.constants.AddressZero) {
                wallets.push({
                    address: item, 
                    balance: "0"
                })
            } else {
                const balance = await getBalance(item)
                wallets.push({
                    address: item, 
                    balance: balance
                })
            }
        }))
    }

    await fs.writeFile(path.join(__dirname, saveTo), JSON.stringify(wallets))

    console.log("Done.")

}

async function getRange(start, end) {
    while(true) {
        try {
            return await token.queryFilter("Transfer",start, end)
        } catch(e) {
            console.error(e)
        }
    }
}

async function getBalance(addr) {
    while(true) {
        try {
            return (await token.balanceOf(addr)).toString()
        } catch(e) {
            console.error(e)
        }
    }
}

main()