// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HospitalRegistry is Ownable {
    
    struct HospitalCapacity {
        string name;
        uint256 icuBeds;
        uint256 emergencyBeds;
        uint256 ventilators;
        uint256 lastUpdated;
        bool verified;
        string[] specializations;
        string location;
        string phoneNumber;
    }
    
    struct CapacityUpdate {
        uint256 timestamp;
        uint256 icuBeds;
        uint256 emergencyBeds;
        uint256 ventilators;
    }
    
    // Mappings
    mapping(address => HospitalCapacity) public hospitals;
    mapping(address => CapacityUpdate[]) public capacityHistory;
    mapping(address => bool) public authorizedUpdaters;
    
    // Arrays for enumeration
    address[] public hospitalAddresses;
    
    // Events
    event HospitalRegistered(
        address indexed hospital,
        string name,
        string location
    );
    
    event CapacityUpdated(
        address indexed hospital,
        uint256 icuBeds,
        uint256 emergencyBeds,
        uint256 ventilators,
        uint256 timestamp
    );
    
    event HospitalVerified(address indexed hospital);
    event UpdaterAuthorized(address indexed updater, address indexed hospital);
    
    // Modifiers
    modifier onlyAuthorizedUpdater(address hospital) {
        require(
            msg.sender == hospital || 
            msg.sender == owner() || 
            authorizedUpdaters[msg.sender],
            "Not authorized to update this hospital"
        );
        _;
    }
    
    modifier onlyVerifiedHospital() {
        require(hospitals[msg.sender].verified, "Hospital not verified");
        _;
    }
    
    /**
     * @dev Register a new hospital
     * @param hospitalAddress Hospital's blockchain address
     * @param name Hospital name
     * @param location Hospital location
     * @param specializations Array of hospital specializations
     * @param phoneNumber Emergency contact number
     */
    function registerHospital(
        address hospitalAddress,
        string memory name,
        string memory location,
        string[] memory specializations,
        string memory phoneNumber
    ) external onlyOwner {
        require(hospitalAddress != address(0), "Invalid hospital address");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(hospitals[hospitalAddress].name).length == 0, "Hospital already registered");
        
        hospitals[hospitalAddress] = HospitalCapacity({
            name: name,
            icuBeds: 0,
            emergencyBeds: 0,
            ventilators: 0,
            lastUpdated: 0,
            verified: false,
            specializations: specializations,
            location: location,
            phoneNumber: phoneNumber
        });
        
        hospitalAddresses.push(hospitalAddress);
        
        emit HospitalRegistered(hospitalAddress, name, location);
    }
    
    /**
     * @dev Update hospital capacity
     * @param icuBeds Available ICU beds
     * @param emergencyBeds Available emergency beds
     * @param ventilators Available ventilators
     */
    function updateCapacity(
        uint256 icuBeds,
        uint256 emergencyBeds,
        uint256 ventilators
    ) external onlyAuthorizedUpdater(msg.sender) {
        require(bytes(hospitals[msg.sender].name).length > 0, "Hospital not registered");
        
        HospitalCapacity storage hospital = hospitals[msg.sender];
        hospital.icuBeds = icuBeds;
        hospital.emergencyBeds = emergencyBeds;
        hospital.ventilators = ventilators;
        hospital.lastUpdated = block.timestamp;
        
        // Store in history
        capacityHistory[msg.sender].push(CapacityUpdate({
            timestamp: block.timestamp,
            icuBeds: icuBeds,
            emergencyBeds: emergencyBeds,
            ventilators: ventilators
        }));
        
        emit CapacityUpdated(msg.sender, icuBeds, emergencyBeds, ventilators, block.timestamp);
    }
    
    /**
     * @dev Update capacity for another hospital (authorized updaters only)
     * @param hospitalAddress Target hospital address
     * @param icuBeds Available ICU beds
     * @param emergencyBeds Available emergency beds  
     * @param ventilators Available ventilators
     */
    function updateCapacityFor(
        address hospitalAddress,
        uint256 icuBeds,
        uint256 emergencyBeds,
        uint256 ventilators
    ) external onlyAuthorizedUpdater(hospitalAddress) {
        require(bytes(hospitals[hospitalAddress].name).length > 0, "Hospital not registered");
        
        HospitalCapacity storage hospital = hospitals[hospitalAddress];
        hospital.icuBeds = icuBeds;
        hospital.emergencyBeds = emergencyBeds;
        hospital.ventilators = ventilators;
        hospital.lastUpdated = block.timestamp;
        
        // Store in history
        capacityHistory[hospitalAddress].push(CapacityUpdate({
            timestamp: block.timestamp,
            icuBeds: icuBeds,
            emergencyBeds: emergencyBeds,
            ventilators: ventilators
        }));
        
        emit CapacityUpdated(hospitalAddress, icuBeds, emergencyBeds, ventilators, block.timestamp);
    }
    
    /**
     * @dev Verify a hospital
     * @param hospitalAddress Hospital to verify
     */
    function verifyHospital(address hospitalAddress) external onlyOwner {
        require(bytes(hospitals[hospitalAddress].name).length > 0, "Hospital not registered");
        hospitals[hospitalAddress].verified = true;
        emit HospitalVerified(hospitalAddress);
    }
    
    /**
     * @dev Authorize an address to update hospital data
     * @param updater Address to authorize
     */
    function authorizeUpdater(address updater) external onlyOwner {
        authorizedUpdaters[updater] = true;
        emit UpdaterAuthorized(updater, msg.sender);
    }
    
    /**
     * @dev Get all hospitals with their current capacity
     */
    function getAllHospitals() external view returns (
        address[] memory addresses,
        HospitalCapacity[] memory capacities
    ) {
        addresses = new address[](hospitalAddresses.length);
        capacities = new HospitalCapacity[](hospitalAddresses.length);
        
        for (uint i = 0; i < hospitalAddresses.length; i++) {
            addresses[i] = hospitalAddresses[i];
            capacities[i] = hospitals[hospitalAddresses[i]];
        }
        
        return (addresses, capacities);
    }
    
    /**
     * @dev Get hospitals with available capacity for emergency type
     * @param emergencyType Type of emergency (not implemented in this version)
     * @param minBeds Minimum beds required
     */
    function getAvailableHospitals(
        string memory emergencyType, // Future use
        uint256 minBeds
    ) external view returns (address[] memory) {
        address[] memory available = new address[](hospitalAddresses.length);
        uint256 count = 0;
        
        for (uint i = 0; i < hospitalAddresses.length; i++) {
            address hospitalAddr = hospitalAddresses[i];
            HospitalCapacity memory hospital = hospitals[hospitalAddr];
            
            if (hospital.verified && 
                (hospital.icuBeds + hospital.emergencyBeds) >= minBeds) {
                available[count] = hospitalAddr;
                count++;
            }
        }
        
        // Resize array to actual count
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = available[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get capacity history for a hospital
     * @param hospitalAddress Hospital address
     * @param limit Maximum number of records to return
     */
    function getCapacityHistory(
        address hospitalAddress, 
        uint256 limit
    ) external view returns (CapacityUpdate[] memory) {
        CapacityUpdate[] storage history = capacityHistory[hospitalAddress];
        uint256 length = history.length;
        
        if (limit > length) {
            limit = length;
        }
        
        CapacityUpdate[] memory result = new CapacityUpdate[](limit);
        
        // Return most recent records
        for (uint256 i = 0; i < limit; i++) {
            result[i] = history[length - 1 - i];
        }
        
        return result;
    }
    
    /**
     * @dev Get total number of registered hospitals
     */
    function getHospitalCount() external view returns (uint256) {
        return hospitalAddresses.length;
    }
}