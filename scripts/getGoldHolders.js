const { get } = require("express/lib/response")

const { ethers } = hre
const fs = require("fs").promises
const holders = new Set()
const outputTo = "holders.json"
const nftAddr = "0x66F703e48F68C03FFFEE0eAee7BE2fE411cB3713"
const earnAddr = "0x2918300B5445Ea9365E30674cF71287a51fa1A51"
const batchSize = 100
const timeout = 5000
let totalSupply
let nft
let earn

async function getHolders() {
    nft = await ethers.getContractAt("IERC721Enumerable", nftAddr)
    earn = await ethers.getContractAt("Earn", earnAddr)
    totalSupply = Number(await nft.totalSupply())
    console.log(`Total supply is ${totalSupply}`)
    for(let i = 0; i < totalSupply; i += batchSize) {
        const size = i + batchSize > totalSupply ? totalSupply - i : batchSize
        const batch = Array.from(Array(size).keys()).map(j => i + j)
        console.log(`Getting holders for list of ${batch}...`)
        let failed = false
        do {
            try {
                const batchHolders = await getHoldersBatch(batch)
                console.log(`Adding holders ${batchHolders}`)
                batchHolders.forEach(holder => holders.add(holder))
            } catch (e) {
                console.log(`failed with ${e}. Retrying...`)
                failed = true
            }
        } while(failed)
    }
    await fs.writeFile(outputTo, JSON.stringify(Array.from(holders)))
}

async function getHoldersBatch(tokenIds) {
    await new Promise(resolve => setTimeout(resolve, timeout))
    const holders = []
    await Promise.all(tokenIds.map(async tokenId => {
        try {
            const holder = await nft.ownerOf(tokenId)
            const location = (await earn.getInformation(tokenId)).location
            if(location[0] == 3 && location[1] == 3) holders.push(holder)
        } catch (e) {
            console.log(`Failed to get holder for token ${tokenId} with ${e}`)
            if(e.message.includes("invalid token ID")) {
                totalSupply ++
            } else throw e
        }
    }))
    return holders
}

getHolders()


