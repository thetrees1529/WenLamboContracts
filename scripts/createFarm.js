const farmManagerAddress = "0x5e8C43Db9f3bD1935ef9cF75240D31c76360B1BC"
const depositTokenAddress = "0x5138f9fDAFdDb313Fff6FdDbAf86FB61734C1ce9"
const vaultAddress = "0xD1655bFc050eA325c1DE46f0D64F0fAE1C51B207"
const rewardTokenAddress = depositTokenAddress
const farmWatcher = hre.ethers.constants.AddressZero
const emissionRate = "10000000000000000"
const startDate = Math.floor(Date.now() / 1000)

async function main() {
    const farmManager = await hre.ethers.getContractAt("FarmManager", farmManagerAddress)
    await (await farmManager.createFarm(
        depositTokenAddress,
        vaultAddress,
        rewardTokenAddress,
        farmWatcher,
        emissionRate,
        startDate
    )).wait()
    const farmsData = await farmManager.getFarmsData()
    console.log("Farm deployed to:", farmsData[farmsData.length - 1].implementation)
}

main()