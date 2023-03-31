

async function main() {
  const FarmManager = await hre.ethers.getContractFactory("FarmManager");
  const farmManager = await FarmManager.deploy();

  await farmManager.deployed();

  console.log("FarmManager deployed to:", farmManager.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

