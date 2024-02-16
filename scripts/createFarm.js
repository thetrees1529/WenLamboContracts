
const farmManagerAddress = "0xAf23cf378a61aB735d8308F212f567cA5bd9Cd9c"
const depositTokenAddress = "0x5138f9fDAFdDb313Fff6FdDbAf86FB61734C1ce9"
const vaultAddress = "0xD1655bFc050eA325c1DE46f0D64F0fAE1C51B207"
const rewardTokenAddress = depositTokenAddress
const farmWatcher = hre.ethers.ZeroAddress
const emissionRate = 1
const emittable = 0
const startDate = Math.floor(Date.now() / 1000)

async function main() {
    const farmManager = await hre.ethers.getContractAt("FarmManager", farmManagerAddress)
    await (await farmManager.createFarm(
        depositTokenAddress,
        vaultAddress,
        rewardTokenAddress,
        farmWatcher,
        emissionRate,
        startDate,
        emittable
    )).wait()
    const farmsData = await farmManager.getFarmsDataFor(hre.ethers.ZeroAddress)
    console.log("Farm deployed to:", farmsData[farmsData.length - 1].implementation)
}

main()