const meta = "test mission"
const duration = 120
const maxCompletionCount = 1
const globalMaxCompletionCount = 5
const qualifyingNft = "0xe8fB7554a7a8c34f139F3caDd76f8f3A7A6FC0bd"
const entryNfts = []
const rewardNfts = []

const missionsAddress = "0x20d56f912775f371FCae3ed2960691BfAc10B972"

async function main() {
    const missions = await ethers.getContractAt("Missions", missionsAddress)
    const tx = await (await missions.createMission(meta, duration, maxCompletionCount, globalMaxCompletionCount, qualifyingNft, entryNfts, rewardNfts)).wait()
    console.log(tx)
}

main()