// scripts/deploy.js
// Deploys TestContract to the specified network

const hre = require("hardhat");

async function main() {
  // Get the contract factory
  const TestContract = await hre.ethers.getContractFactory("TestContract");

  // Deploy with an initial message
  const testContract = await TestContract.deploy("Hello MedChain!");

  await testContract.deployed();

  console.log("TestContract deployed to:", testContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
