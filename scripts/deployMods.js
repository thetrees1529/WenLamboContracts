const randomAddress = "0x0305AcBe6a99ABe9ba00647A730104CB12B95032"
const toolboxesAddress = "0x3Bea526Ae0fB5b68D51702Bb67a03836D599191B"
const name = "Mods"
const symbol = "MODS"
const modsURI = "modsUri"
const nfvsAddress = "0x0c6abF36D8945720B28E05EE5EdcDa01f18a0cea"
const perInputs = [["bronze",[1,100]],["silver",[2,100]],["gold",[3,100]]]
const attributeConfigs = ["tires","power", "handing","speed"]
const attributeBruh = [["tires",1],["handing",1],["speed",1]]

async function main() {
    const toolboxes = await ethers.getContractAt("Toolboxes", toolboxesAddress)
    const nfvs = await ethers.getContractAt("Nfvs", nfvsAddress)
    const random = await ethers.getContractAt("Random", randomAddress)
    const Mods = await ethers.getContractFactory("Mods");
    const mods =  await (await Mods.deploy( name,symbol,modsURI,toolboxes.address, random.address,nfvs.address, perInputs,attributeConfigs, attributeBruh)).deployed();
    await (await random.grantRole(await random.CONSUMER_ROLE(), mods.address)).wait()
    await (await toolboxes.grantRole(await toolboxes.BURNER_ROLE(), mods.address)).wait()
    console.log("Mods deployed to:", mods.address);
}

main()