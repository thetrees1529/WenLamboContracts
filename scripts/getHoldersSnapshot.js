const {ethers} = hre
const tokenAddr = "0xF9565E8c4E13862f677F144B3cdC8700D9c4BA31"
const deployedAt = 22899567
const saveTo = "holders.json"
const fs = require("fs").promises
const path = require("path")
const interval = 1024

let token

async function main() {

    const holders = new Set()
    token = await ethers.getContractAt("IERC20", tokenAddr)

    const lastBlock = (await ethers.provider.getBlock()).number - interval + 1;
    
    for(let i = deployedAt; i <= lastBlock; i += interval) {
        const to = i + interval
        console.log(`scanning blocks ${i} through ${to}.`)
        let success = false
        let range
        while(!success) {
            try {
                range = await getRange(i, to)
                success = true
            } catch(e) {
                console.error(e)
            }
        }

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
    }

    let balances = Array.from(holders.keys())

    for(i in balances) {
        const addr = balances[i]
        balances[i] = {}
        balances[i].addr = addr
        if(addr == ethers.constants.AddressZero) {
            balances[i].balance = 0
            continue
        }
        let success = false
        while(!success) {
            try {
                balances[i].balance = (await token.balanceOf(addr)).toString()
                success = true
            } catch(e) {
                console.error(e)
            }
        }
    }

    await fs.writeFile(path.join(__dirname, saveTo), JSON.stringify(balances))

    console.log("Done.")

}

async function getRange(start, end) {
    return await token.queryFilter("Transfer",start,end)
}

main()