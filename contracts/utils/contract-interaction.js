// utils/contract-interaction.js

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

let contractAddress;
try {
  const addressFile = path.join(__dirname, '../contract-address/hospital-registry-address.json');
  contractAddress = JSON.parse(fs.readFileSync(addressFile)).HospitalRegistry;
} catch (error) {
  console.error('Error loading contract address:', error);
  contractAddress = process.env.HOSPITAL_REGISTRY_ADDRESS;
}

const contractABI = require('../artifacts/contracts/HospitalRegistry.sol/HospitalRegistry.json').abi;

class ContractInteraction {
  constructor(providerUrl = null, privateKey = null) {
    this.provider = providerUrl 
      ? new ethers.providers.JsonRpcProvider(providerUrl)
      : new ethers.providers.Web3Provider(window.ethereum);
    
    // If privateKey is provided, create a wallet signer
    if (privateKey) {
      this.signer = new ethers.Wallet(privateKey, this.provider);
    } else {
      this.signer = this.provider.getSigner();
    }
    
    this.contract = new ethers.Contract(contractAddress, contractABI, this.signer);
  }

  async connectWallet() {
    try {
      if (!window.ethereum) {
        throw new Error('No Ethereum provider found. Please install MetaMask or another wallet.');
      }
      
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      
      const account = accounts[0];
      
      this.provider = new ethers.providers.Web3Provider(window.ethereum);
      this.signer = this.provider.getSigner();
      this.contract = new ethers.Contract(contractAddress, contractABI, this.signer);
      
      return { success: true, account };
    } catch (error) {
      console.error('Error connecting to wallet:', error);
      return { success: false, error: error.message };
    }
  }

  async getAllHospitals() {
    try {
      const result = await this.contract.getAllHospitals();
      return {
        success: true,
        addresses: result.addresses,
        capacities: result.capacities
      };
    } catch (error) {
      console.error('Error getting hospitals:', error);
      return { success: false, error: error.message };
    }
  }

  async getAvailableHospitals(emergencyType, minBeds) {
    try {
      const result = await this.contract.getAvailableHospitals(emergencyType, minBeds);
      return { success: true, hospitals: result };
    } catch (error) {
      console.error('Error getting available hospitals:', error);
      return { success: false, error: error.message };
    }
  }

  // Update hospital capacity
  async updateCapacity(icuBeds, emergencyBeds, ventilators) {
    try {
      const tx = await this.contract.updateCapacity(icuBeds, emergencyBeds, ventilators);
      await tx.wait();
      return { success: true, transactionHash: tx.hash };
    } catch (error) {
      console.error('Error updating capacity:', error);
      return { success: false, error: error.message };
    }
  }

  // Update capacity for a specific hospital (admin only)
  async updateCapacityFor(hospitalAddress, icuBeds, emergencyBeds, ventilators) {
    try {
      const tx = await this.contract.updateCapacityFor(
        hospitalAddress, 
        icuBeds, 
        emergencyBeds, 
        ventilators
      );
      await tx.wait();
      return { success: true, transactionHash: tx.hash };
    } catch (error) {
      console.error('Error updating capacity for hospital:', error);
      return { success: false, error: error.message };
    }
  }

  // Register a new hospital (admin only)
  async registerHospital(hospitalAddress, name, location, specializations, phoneNumber) {
    try {
      const tx = await this.contract.registerHospital(
        hospitalAddress,
        name,
        location,
        specializations,
        phoneNumber
      );
      await tx.wait();
      return { success: true, transactionHash: tx.hash };
    } catch (error) {
      console.error('Error registering hospital:', error);
      return { success: false, error: error.message };
    }
  }

  // Verify a hospital (admin only)
  async verifyHospital(hospitalAddress) {
    try {
      const tx = await this.contract.verifyHospital(hospitalAddress);
      await tx.wait();
      return { success: true, transactionHash: tx.hash };
    } catch (error) {
      console.error('Error verifying hospital:', error);
      return { success: false, error: error.message };
    }
  }

  // Get capacity history for a hospital
  async getCapacityHistory(hospitalAddress, limit) {
    try {
      const result = await this.contract.getCapacityHistory(hospitalAddress, limit);
      return { success: true, history: result };
    } catch (error) {
      console.error('Error getting capacity history:', error);
      return { success: false, error: error.message };
    }
  }
}

module.exports = ContractInteraction;
