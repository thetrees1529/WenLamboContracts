const farmManagerAddress = "0xF687ef31154218f2c4c9C39a7005e25e1dE0702a"
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
    )).waitForTransaction()
    const farmsData = await farmManager.getFarmsDataFor(hre.ethers.constants.AddressZero)
    console.log("Farm deployed to:", farmsData[farmsData.length - 1].implementation)
}

main()