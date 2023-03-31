const randomAddress = "0x0305AcBe6a99ABe9ba00647A730104CB12B95032"
const toolboxesAddress = "0x3Bea526Ae0fB5b68D51702Bb67a03836D599191B"
const name = "Mods"
const symbol = "MODS"
const modsURI = "modsUri"
const nfvsAddress = "0x0c6abF36D8945720B28E05EE5EdcDa01f18a0cea"
const options = [[0,1],[1,1],[2,1],[3,1]]
const perInputs = [[0,1],[1,2],[2,3]]
const attributeConfigs = [["tires",100],["power",100], ["handing",100],["speed",100]]

async function main() {
    const toolboxes = await ethers.getContractAt("Toolboxes", toolboxesAddress)
    const nfvs = await ethers.getContractAt("Nfvs", nfvsAddress)
    const random = await ethers.getContractAt("Random", randomAddress)
    const Mods = await ethers.getContractFactory("Mods");
    const mods =  await (await Mods.deploy(toolboxes.address, random.address, name,symbol,modsURI,options,perInputs,attributeConfigs, nfvs.address)).deployed();
    await (await random.grantRole(await random.CONSUMER_ROLE(), mods.address)).wait()
    console.log("Mods deployed to:", mods.address);
}

main()