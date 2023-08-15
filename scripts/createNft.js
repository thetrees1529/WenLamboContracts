const { ethers } = hre

const name = "test"
const symbol = "TST"
const baseURI = "https://test.com/"

async function main() {
    console.log("Nft deployed at ",(await (await ethers.deployContract("Nft",[baseURI,name,symbol])).waitForDeployment()).target)
}

main()