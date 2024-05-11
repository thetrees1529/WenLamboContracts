const {ethers} = hre
const earnOld = "0xCa8454a254AAC452a609c376F1959303be4Bf2B0"
async function main() {
    const earn2 = await (await ethers.deployContract("FinalEarn", [earnOld])).waitForDeployment()
    const token = await ethers.getContractAt("Token", (await earn2.getInfo()).token)
    await (await token.grantRole(await token.TOKEN_MAESTRO_ROLE(), earn2.target)).wait()
    console.log("Earn2 deployed to:", earn2.target)
}
main()