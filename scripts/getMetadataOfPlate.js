const {ethers} = hre

const metadataAddress = "0x53049c1701A2f9964bd54A3F805F75D0b6F204e4"
const plate = 0

async function main() {
    const metadata = await ethers.getContractAt("PlateMetadata", metadataAddress)
    console.log(await metadata.getMetadataOf(plate))
}

main()