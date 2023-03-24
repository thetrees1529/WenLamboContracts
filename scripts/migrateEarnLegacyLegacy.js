const { ethers } = hre

const contractAddress = "0xE94b2CB054D88e1763c1D01DB66005d0de37782d"
const start = 0
const end = 25
const interval = 25

let migrator
const abi = ["function migrate(uint[] tokenIds);"]

async function main() {
    migrator = await ethers.getContractAt(abi, contractAddress)

    for(let i = start; i < end - start; i += interval) {

        const tokenIds = Array.from(Array(interval).keys()).map(el => el + i)
        await migrate(tokenIds)

    }
}

async function migrate(tokenIds) {
    console.log("Doing: ",tokenIds)

    await (await migrator.migrateList(tokenIds)).wait()

}

main()
