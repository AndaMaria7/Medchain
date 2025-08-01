// scripts/deploy_emergency_coordinator.js
// Deploys EmergencyCoordinator contract to the specified network with detailed logging

const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  try {
    console.log("Starting EmergencyCoordinator deployment process...");
    console.log("Network:", hre.network.name);
    
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");

    console.log("Compiling EmergencyCoordinator contract...");
    const EmergencyCoordinator = await hre.ethers.getContractFactory("EmergencyCoordinator");

    console.log("Deploying EmergencyCoordinator...");
    const deploymentStart = Date.now();
    const emergencyCoordinator = await EmergencyCoordinator.deploy();
    console.log("Deployment transaction sent! Transaction hash:", emergencyCoordinator.deploymentTransaction().hash);
    
    // Wait for deployment transaction to be mined
    console.log("Waiting for deployment transaction to be mined (this may take a few minutes)...");
    const txReceipt = await emergencyCoordinator.deploymentTransaction().wait(1);
    const deployTime = (Date.now() - deploymentStart) / 1000;
    console.log(`Deployment confirmed in ${deployTime.toFixed(2)} seconds`);
    
    const contractAddress = txReceipt.contractAddress;
    console.log("Gas used for deployment:", txReceipt.gasUsed.toString());
    console.log("EmergencyCoordinator deployed to:", contractAddress);
    console.log("Transaction hash:", emergencyCoordinator.deploymentTransaction().hash);
    
    const contractAddressDir = path.join(__dirname, '..', '..', 'mobile', 'assets', 'contract-address');
    
    if (!fs.existsSync(contractAddressDir)) {
      fs.mkdirSync(contractAddressDir, { recursive: true });
    }
    
    // Save to network-specific file
    const networkFileName = `emergency-coordinator-address-${hre.network.name}.json`;
    const networkAddressFilePath = path.join(contractAddressDir, networkFileName);
    
    fs.writeFileSync(
      networkAddressFilePath,
      JSON.stringify({ address: contractAddress }, null, 2)
    );
    
    console.log(`Contract address saved to ${networkAddressFilePath}`);
    
    // Also save to the default file for backward compatibility
    const defaultAddressFilePath = path.join(contractAddressDir, 'emergency-coordinator-address.json');
    
    fs.writeFileSync(
      defaultAddressFilePath,
      JSON.stringify({ address: contractAddress }, null, 2)
    );
    
    console.log(`Contract address also saved to ${defaultAddressFilePath}`);
    
    // Copy the contract ABI to the mobile assets directory
    const contractsDir = path.join(__dirname, '..', 'artifacts', 'contracts', 'EmergencyCoordinator.sol');
    const abiDir = path.join(__dirname, '..', '..', 'mobile', 'assets', 'contracts');
    
    if (!fs.existsSync(abiDir)) {
      fs.mkdirSync(abiDir, { recursive: true });
    }
    
    const abiSourcePath = path.join(contractsDir, 'EmergencyCoordinator.json');
    const abiTargetPath = path.join(abiDir, 'EmergencyCoordinator.json');
    
    if (fs.existsSync(abiSourcePath)) {
      fs.copyFileSync(abiSourcePath, abiTargetPath);
      console.log(`Contract ABI copied to ${abiTargetPath}`);
    } else {
      console.error(`ABI file not found at ${abiSourcePath}`);
    }
  } catch (error) {
    console.error("Error during deployment:", error);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed with error:", error);
    process.exit(1);
  });
