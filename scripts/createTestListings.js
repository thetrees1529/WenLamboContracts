const { ethers } = hre

const target = "0xd820FF08e5852a9fa668a5686D0852D99A33C9EE" 
const WAVAX = "0xd00ae08403b9bbb9124bb305c09058e32c39a48c"
const prices = [1e17, 1e18, 15e16, 15e17, 2e17].map(price => BigInt(price))
const durations = [60 * 60 * 24 * 7, 60 * 60 * 24 * 30, 60 * 60 * 24 * 365]

const perCollection = 5
const numberOfCollections = 3



let address

let marketplace
async function main() {
    address = (await ethers.getSigners())[0].address
    marketplace = await ethers.getContractAt("Marketplace", target)
    for (let i = 0; i < numberOfCollections; i ++) {
        await list(perCollection)
    }
}

let nonce = 0
async function list(numberOf) {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = await (await Nft.deploy("",`Test collection ${nonce}`, `COL${nonce ++}`)).waitForDeployment()
    await (await marketplace.whitelist(nft.target)).wait()
    await (await nft.mint(address, numberOf)).wait()
    await (await nft.setApprovalForAll(marketplace.target, true)).wait()
    const tokenIds = Array.from(new Array(numberOf).keys())
    const inputs = tokenIds.map(tokenId => ({
        col: nft.target,
        tokenId,
        token: WAVAX,
        amount: prices[Math.floor(Math.random() * prices.length)],
        expiry: Math.floor(Date.now()/1000) + durations[Math.floor(Math.random() * durations.length)]
    }))
    await (await marketplace.multiList(inputs)).wait()
}

main()
