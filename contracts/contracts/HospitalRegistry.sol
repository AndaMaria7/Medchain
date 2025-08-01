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
        uint256 personnelLastUpdated;
    }
    
    mapping(address => mapping(string => uint256)) public hospitalMedicalPersonnel;
    
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
    
    // Medical personnel tracking
    struct PersonnelUpdate {
        uint256 timestamp;
        string specialistType;
        uint256 count;
    }
    
    mapping(address => PersonnelUpdate[]) public personnelHistory;
    
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
    
    event MedicalPersonnelUpdated(
        address indexed hospital,
        string specialistType,
        uint256 count,
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
        
        hospitals[hospitalAddress].name = name;
        hospitals[hospitalAddress].icuBeds = 0;
        hospitals[hospitalAddress].emergencyBeds = 0;
        hospitals[hospitalAddress].ventilators = 0;
        hospitals[hospitalAddress].lastUpdated = 0;
        hospitals[hospitalAddress].verified = false;
        hospitals[hospitalAddress].specializations = specializations;
        hospitals[hospitalAddress].location = location;
        hospitals[hospitalAddress].phoneNumber = phoneNumber;
        hospitals[hospitalAddress].personnelLastUpdated = 0;
        
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
        // Auto-register hospital if not already registered
        if (bytes(hospitals[msg.sender].name).length == 0) {
            hospitals[msg.sender].name = "Auto-registered Hospital";
            hospitals[msg.sender].location = "Unknown Location";
            hospitals[msg.sender].phoneNumber = "";
            hospitals[msg.sender].verified = false;
            hospitalAddresses.push(msg.sender);
        }
        
        HospitalCapacity storage hospital = hospitals[msg.sender];
        hospital.icuBeds = icuBeds;
        hospital.emergencyBeds = emergencyBeds;
        hospital.ventilators = ventilators;
        hospital.lastUpdated = block.timestamp;
        
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
        string memory emergencyType, 
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
        
        for (uint256 i = 0; i < limit; i++) {
            result[i] = history[length - 1 - i];
        }
        
        return result;
    }
    
    /**
     * @dev Update medical personnel availability
     * @param specialistTypes Array of specialist types
     * @param counts Array of counts for each specialist type
     */
    function updateMedicalPersonnel(
        string[] memory specialistTypes,
        uint256[] memory counts
    ) external onlyAuthorizedUpdater(msg.sender) {
        require(specialistTypes.length == counts.length, "Arrays length mismatch");
        
        if (bytes(hospitals[msg.sender].name).length == 0) {
            hospitals[msg.sender].name = "Auto-registered Hospital";
            hospitals[msg.sender].location = "Unknown Location";
            hospitals[msg.sender].phoneNumber = "";
            hospitals[msg.sender].verified = false;
            hospitalAddresses.push(msg.sender);
        }
        
        HospitalCapacity storage hospital = hospitals[msg.sender];
        hospital.personnelLastUpdated = block.timestamp;
        
        for (uint256 i = 0; i < specialistTypes.length; i++) {
            string memory specialistType = specialistTypes[i];
            uint256 count = counts[i];
            
            hospitalMedicalPersonnel[msg.sender][specialistType] = count;
            
            personnelHistory[msg.sender].push(PersonnelUpdate({
                timestamp: block.timestamp,
                specialistType: specialistType,
                count: count
            }));
            
            emit MedicalPersonnelUpdated(msg.sender, specialistType, count, block.timestamp);
        }
    }
    
    /**
     * @dev Update medical personnel for a specific hospital by owner
     * @param hospitalAddress Hospital address
     * @param specialistTypes Array of specialist types
     * @param counts Array of counts for each specialist type
     */
    function updateHospitalPersonnel(
        address hospitalAddress,
        string[] memory specialistTypes,
        uint256[] memory counts
    ) external onlyOwner {
        require(bytes(hospitals[hospitalAddress].name).length > 0, "Hospital not registered");
        require(specialistTypes.length == counts.length, "Arrays length mismatch");
        
        HospitalCapacity storage hospital = hospitals[hospitalAddress];
        hospital.personnelLastUpdated = block.timestamp;
        
        for (uint256 i = 0; i < specialistTypes.length; i++) {
            string memory specialistType = specialistTypes[i];
            uint256 count = counts[i];
            
            hospitalMedicalPersonnel[hospitalAddress][specialistType] = count;
            
            personnelHistory[hospitalAddress].push(PersonnelUpdate({
                timestamp: block.timestamp,
                specialistType: specialistType,
                count: count
            }));
            
            emit MedicalPersonnelUpdated(hospitalAddress, specialistType, count, block.timestamp);
        }
    }
    
    /**
     * @dev Get personnel history for a hospital
     * @param hospitalAddress Hospital address
     * @param limit Maximum number of records to return
     */
    function getPersonnelHistory(
        address hospitalAddress, 
        uint256 limit
    ) external view returns (PersonnelUpdate[] memory) {
        PersonnelUpdate[] storage history = personnelHistory[hospitalAddress];
        uint256 length = history.length;
        
        if (limit > length) {
            limit = length;
        }
        
        PersonnelUpdate[] memory result = new PersonnelUpdate[](limit);
        
        for (uint256 i = 0; i < limit; i++) {
            result[i] = history[length - 1 - i];
        }
        
        return result;
    }
    
    /**
     * @dev Get current personnel count for a specific specialist type
     * @param hospitalAddress Hospital address
     * @param specialistType Type of specialist
     */
    function getPersonnelCount(
        address hospitalAddress,
        string memory specialistType
    ) external view returns (uint256) {
        require(bytes(hospitals[hospitalAddress].name).length > 0, "Hospital not registered");
        return hospitalMedicalPersonnel[hospitalAddress][specialistType];
    }
    
    /**
     * @dev Get total number of registered hospitals
     */
    function getHospitalCount() external view returns (uint256) {
        return hospitalAddresses.length;
    }
}