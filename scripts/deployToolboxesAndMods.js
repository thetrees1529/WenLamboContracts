const randomAddress = "0x0305AcBe6a99ABe9ba00647A730104CB12B95032"
//toolboxes
const toolboxesUri = "bruh"
const toolboxesName = "toolboxes"
const toolboxesSymbol = "tboxes"
const tokenAddress = "0x5138f9fDAFdDb313Fff6FdDbAf86FB61734C1ce9"
const payees = [["0xABCD0baDa7ad8d922DD687Cc61FFc65c75C2F8FD",1]]
const price = "100000000000000000000"
const config = [["bronze",1],["silver",1],["gold",1]]

//mods
const name = "Mods"
const symbol = "MODS"
const modsURI = "modsUri"
const nfvsAddress = "0x0c6abF36D8945720B28E05EE5EdcDa01f18a0cea"
const valuePerToolboxes = [["bronze",1],["silver",2],["gold",3]]
const attributeList = ["tires","power", "handling","speed"]
const configs = [["tires",1],["handling",1],["speed",1],["power",1]]
const maxPerCars = [["tires",100],["handling",100],["speed",100],["power",100]]

//deploy and set roles
async function main() {
    const token = await ethers.getContractAt("Token", tokenAddress)
    const nfvs = await ethers.getContractAt("Nfvs", nfvsAddress)
    const random = await ethers.getContractAt("IRandom", randomAddress)
    const Toolboxes = await ethers.getContractFactory("Toolboxes");
    const toolboxes =  await (await Toolboxes.deploy(toolboxesUri, toolboxesName, toolboxesSymbol, token.address, random.address, config, price, payees)).deployed();
    const Mods = await ethers.getContractFactory("Mods");
    const mods =  await (await Mods.deploy( name,symbol,modsURI,toolboxes.address, random.address,nfvs.address, maxPerCars,attributeList, configs, valuePerToolboxes)).deployed();
    await (await token.grantRole(await token.TOKEN_MAESTRO_ROLE(), toolboxes.address)).wait()
    await (await (await ethers.getContractAt("AccessControl",random.address)).grantRole(await random.CONSUMER_ROLE(), toolboxes.address)).wait()
    await (await (await ethers.getContractAt("AccessControl",random.address)).grantRole(await random.CONSUMER_ROLE(), mods.address)).wait()
    await (await (await ethers.getContractAt("AccessControl",toolboxes.address)).grantRole(await toolboxes.BURNER_ROLE(), mods.address)).wait()
    console.log("Toolboxes deployed to:", toolboxes.address);
    console.log("Mods deployed to:", mods.address);
}

main()