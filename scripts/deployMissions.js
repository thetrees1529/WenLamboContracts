const {ethers} = hre

async function main() {
    const missions = await (await ethers.deployContract("Missions")).waitForDeployment()
    console.log(missions)
    console.log('Missions address:', missions.target)
}

main()