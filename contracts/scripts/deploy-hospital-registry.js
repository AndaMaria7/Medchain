// scripts/deploy-hospital-registry.js

const hre = require("hardhat");

async function main() {
  const HospitalRegistry = await hre.ethers.getContractFactory("HospitalRegistry");

  console.log("Deploying HospitalRegistry...");
  const hospitalRegistry = await HospitalRegistry.deploy();

  await hospitalRegistry.deployed();

  console.log("HospitalRegistry deployed to:", hospitalRegistry.address);
  
  const fs = require("fs");
  const contractsDir = __dirname + "/../contract-address";
  
  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }
  
  fs.writeFileSync(
    contractsDir + "/hospital-registry-address.json",
    JSON.stringify({ HospitalRegistry: hospitalRegistry.address }, undefined, 2)
  );
  
  console.log("Contract address saved to hospital-registry-address.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
