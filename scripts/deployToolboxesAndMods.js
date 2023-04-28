const randomAddress = "0x0305AcBe6a99ABe9ba00647A730104CB12B95032"
//toolboxes
const toolboxesUri = "bruh"
const toolboxesName = "tboxes"
const tokenAddress = "0x5138f9fDAFdDb313Fff6FdDbAf86FB61734C1ce9"
const payees = [["0xABCD0baDa7ad8d922DD687Cc61FFc65c75C2F8FD",1]]
const price = "100000000000000000000"
const config = [[0,1],[1,1],[2,1]]

//mods
const name = "Mods"
const symbol = "MODS"
const modsURI = "modsUri"
const nfvsAddress = "0x0c6abF36D8945720B28E05EE5EdcDa01f18a0cea"
const options = [[0,1],[1,1],[2,1],[3,1]]
const perInputs = [[0,1],[1,2],[2,3]]
const attributeConfigs = [["tires",100],["power",100], ["handing",100],["speed",100]]

//deploy and set roles
async function main() {
    const token = await ethers.getContractAt("Token", tokenAddress)
    const nfvs = await ethers.getContractAt("Nfvs", nfvsAddress)
    const random = await ethers.getContractAt("IRandom", randomAddress)
    const Toolboxes = await ethers.getContractFactory("Toolboxes");
    const toolboxes =  await (await Toolboxes.deploy(toolboxesUri, toolboxesName, random.address, token.address, payees, price, config)).deployed();
    const Mods = await ethers.getContractFactory("Mods");
    const mods =  await (await Mods.deploy(toolboxes.address, random.address, name,symbol,modsURI,options,perInputs,attributeConfigs, nfvs.address)).deployed();
    await (await token.grantRole(await token.TOKEN_MAESTRO_ROLE(), toolboxes.address)).wait()
    await (await (await ethers.getContractAt("AccessControl",random.address)).grantRole(await random.CONSUMER_ROLE(), toolboxes.address)).wait()
    await (await (await ethers.getContractAt("AccessControl",random.address)).grantRole(await random.CONSUMER_ROLE(), mods.address)).wait()
    console.log("Toolboxes deployed to:", toolboxes.address);
    console.log("Mods deployed to:", mods.address);
}

main()