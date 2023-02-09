const hre = require("hardhat");

async function main() {

  const BBC = await hre.ethers.getContractFactory("BBC");
  const bBC = await BBC.deploy("0x4bc4bba990fe31d529d987f7b8ccf79f1626e559");

  await bBC.deployed("0x4bc4bba990fe31d529d987f7b8ccf79f1626e559");

  console.log("BBC deployed to:", bBC.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
