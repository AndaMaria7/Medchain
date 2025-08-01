// scripts/deploy.js
// Deploys HospitalRegistry contract to the specified network

const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  const HospitalRegistry = await hre.ethers.getContractFactory("HospitalRegistry");

  console.log("Deploying HospitalRegistry...");
  const hospitalRegistry = await HospitalRegistry.deploy();
  
  // Wait for deployment transaction to be mined
  await hospitalRegistry.deploymentTransaction().wait();
  
  // Get the contract address
  const deployTx = hospitalRegistry.deploymentTransaction();
  const txReceipt = await deployTx.wait();
  const contractAddress = txReceipt.contractAddress;
  
  console.log("HospitalRegistry deployed to:", contractAddress);
  
  const contractAddressDir = path.join(__dirname, '..', '..', 'mobile', 'assets', 'contract-address');
  
  if (!fs.existsSync(contractAddressDir)) {
    fs.mkdirSync(contractAddressDir, { recursive: true });
  }
  
  const addressFilePath = path.join(contractAddressDir, 'hospital-registry-address.json');
  
  fs.writeFileSync(
    addressFilePath,
    JSON.stringify({ address: contractAddress }, null, 2)
  );
  
  console.log(`Contract address saved to ${addressFilePath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
