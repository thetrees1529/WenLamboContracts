const vaultAddress = "0xD1655bFc050eA325c1DE46f0D64F0fAE1C51B207"
async function main() {
  const vault = await hre.ethers.getContractAt("Vault", vaultAddress)
  const FarmManager = await hre.ethers.getContractFactory("FarmManager");
  const farmManager = await FarmManager.deploy();
  await farmManager.waitForDeployment();
  await (await vault.grantRole(await vault.DEFAULT_ADMIN_ROLE(), farmManager.target)).wait()
  console.log("FarmManager deployed to:", farmManager.target);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });