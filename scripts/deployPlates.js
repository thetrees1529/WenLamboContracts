

const {ethers} = hre

const price = ethers.parseEther("0.001")
const maxMinted = 100
const backgrounds = ["GB", "US"]

async function main() {

    const plates = await(await ethers.deployContract("Plates")).waitForDeployment()
    const metadata = await (await ethers.deployContract("PlateMetadata", [plates.target])).waitForDeployment()
    const register = await (await ethers.deployContract("PlateRegister", [metadata.target])).waitForDeployment()
    const mint = await (await ethers.deployContract("MintPlates", [plates.target, register.target, price, maxMinted])).waitForDeployment()

    await(await register.setBackgrounds(backgrounds)).wait()
    await(await plates.grantRole(await plates.MINTER_ROLE(), mint.target)).wait()
    await(await metadata.grantRole(await metadata.DEFAULT_ADMIN_ROLE(), register.target)).wait()
    await(await register.grantRole(await register.DEFAULT_ADMIN_ROLE(), mint.target)).wait()

    console.log("Plates deployed to:", plates.target)
    console.log("Metadata deployed to:", metadata.target)
    console.log("Register deployed to:", register.target)
    console.log("Mint deployed to:", mint.target)
    console.log("Register config: ", await register.getRules())

}

main()
