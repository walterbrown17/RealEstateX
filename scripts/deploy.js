const hre = require("hardhat");

async function main() {
  const RealEstateX = await hre.ethers.getContractFactory("RealEstateX");
  const realEstateX = await RealEstateX.deploy();

  await realEstateX.deployed();

  console.log(
    `RealEstateX deployed to Core Blockchain at address: ${realEstateX.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
