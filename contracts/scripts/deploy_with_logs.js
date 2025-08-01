// scripts/deploy_with_logs.js
// Deploys HospitalRegistry contract to the specified network with detailed logging

const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  console.log("Starting deployment process...");
  console.log("Network:", hre.network.name);
  
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const HospitalRegistry = await hre.ethers.getContractFactory("HospitalRegistry");

  console.log("Deploying HospitalRegistry...");
  const hospitalRegistry = await HospitalRegistry.deploy();
  
  console.log("Waiting for deployment transaction to be mined...");
  await hospitalRegistry.deploymentTransaction().wait();
  
  const deployTx = hospitalRegistry.deploymentTransaction();
  const txReceipt = await deployTx.wait();
  const contractAddress = txReceipt.contractAddress;
  
  console.log("HospitalRegistry deployed to:", contractAddress);
  console.log("Transaction hash:", deployTx.hash);
  
  const contractAddressDir = path.join(__dirname, '..', '..', 'mobile', 'assets', 'contract-address');
  
  if (!fs.existsSync(contractAddressDir)) {
    fs.mkdirSync(contractAddressDir, { recursive: true });
  }
  
  const networkFileName = `hospital-registry-address-${hre.network.name}.json`;
  const networkAddressFilePath = path.join(contractAddressDir, networkFileName);
  
  fs.writeFileSync(
    networkAddressFilePath,
    JSON.stringify({ address: contractAddress }, null, 2)
  );
  
  console.log(`Contract address saved to ${networkAddressFilePath}`);
  
  // Also save to the default file for backward compatibility
  const defaultAddressFilePath = path.join(contractAddressDir, 'hospital-registry-address.json');
  
  fs.writeFileSync(
    defaultAddressFilePath,
    JSON.stringify({ address: contractAddress }, null, 2)
  );
  
  console.log(`Contract address also saved to ${defaultAddressFilePath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed with error:", error);
    process.exit(1);
  });
