// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EmergencyCoordinator is Ownable, ReentrancyGuard {
    
    struct Emergency {
        string emergencyId;
        address patient;
        string location;
        uint256 severity;
        string emergencyType;
        string matchedHospitalId;
        uint256 matchScore;
        uint256 timestamp;
        bool isResolved;
        string oceanJobId; // Links to Ocean C2D job
    }
    
    struct Hospital {
        address hospitalAddress;
        string hospitalId;
        string name;
        bool isVerified;
        bool isActive;
    }
    
    // Mappings
    mapping(string => Emergency) public emergencies;
    mapping(address => Hospital) public hospitals;
    mapping(string => address) public hospitalIdToAddress;
    
    // Events
    event EmergencyCreated(
        string indexed emergencyId,
        address indexed patient,
        string location,
        uint256 severity,
        string emergencyType
    );
    
    event EmergencyMatched(
        string indexed emergencyId,
        string hospitalId,
        uint256 matchScore,
        string oceanJobId
    );
    
    event EmergencyResolved(
        string indexed emergencyId,
        address indexed hospital
    );
    
    event HospitalRegistered(
        address indexed hospitalAddress,
        string hospitalId,
        string name
    );
    
    // Modifiers
    modifier onlyVerifiedHospital() {
        require(hospitals[msg.sender].isVerified, "Not a verified hospital");
        _;
    }
    
    modifier emergencyExists(string memory emergencyId) {
        require(bytes(emergencies[emergencyId].emergencyId).length > 0, "Emergency does not exist");
        _;
    }
    
    /**
     * @dev Create a new emergency record
     * @param emergencyId Unique identifier for the emergency
     * @param location Patient location (could be coordinates or address)
     * @param severity Emergency severity (1-10 scale)
     * @param emergencyType Type of emergency (cardiac, trauma, etc.)
     */
    function createEmergency(
        string memory emergencyId,
        string memory location,
        uint256 severity,
        string memory emergencyType
    ) external nonReentrant returns (bool) {
        require(bytes(emergencyId).length > 0, "Emergency ID cannot be empty");
        require(severity >= 1 && severity <= 10, "Severity must be between 1-10");
        require(bytes(emergencies[emergencyId].emergencyId).length == 0, "Emergency already exists");
        
        emergencies[emergencyId] = Emergency({
            emergencyId: emergencyId,
            patient: msg.sender,
            location: location,
            severity: severity,
            emergencyType: emergencyType,
            matchedHospitalId: "",
            matchScore: 0,
            timestamp: block.timestamp,
            isResolved: false,
            oceanJobId: ""
        });
        
        emit EmergencyCreated(emergencyId, msg.sender, location, severity, emergencyType);
        return true;
    }
    
    /**
     * @dev Update emergency with Ocean C2D matching results
     * @param emergencyId The emergency to update
     * @param hospitalId Matched hospital ID
     * @param matchScore Matching score from Ocean algorithm
     * @param oceanJobId Ocean Protocol compute job ID
     */
    function updateEmergencyMatch(
        string memory emergencyId,
        string memory hospitalId,
        uint256 matchScore,
        string memory oceanJobId
    ) external emergencyExists(emergencyId) nonReentrant {
        Emergency storage emergency = emergencies[emergencyId];
        
        // Only patient or contract owner can update
        require(
            msg.sender == emergency.patient || msg.sender == owner(),
            "Not authorized to update this emergency"
        );
        
        require(!emergency.isResolved, "Emergency already resolved");
        require(matchScore <= 100, "Match score cannot exceed 100");
        
        emergency.matchedHospitalId = hospitalId;
        emergency.matchScore = matchScore;
        emergency.oceanJobId = oceanJobId;
        
        emit EmergencyMatched(emergencyId, hospitalId, matchScore, oceanJobId);
    }
    
    /**
     * @dev Resolve emergency (called by hospital)
     * @param emergencyId The emergency to resolve
     */
    function resolveEmergency(string memory emergencyId) 
        external 
        emergencyExists(emergencyId) 
        onlyVerifiedHospital 
        nonReentrant 
    {
        Emergency storage emergency = emergencies[emergencyId];
        
        // Check if hospital is the matched one
        require(
            keccak256(bytes(hospitals[msg.sender].hospitalId)) == 
            keccak256(bytes(emergency.matchedHospitalId)),
            "Hospital not matched to this emergency"
        );
        
        require(!emergency.isResolved, "Emergency already resolved");
        
        emergency.isResolved = true;
        
        emit EmergencyResolved(emergencyId, msg.sender);
    }
    
    /**
     * @dev Register a new hospital
     * @param hospitalAddress Hospital's blockchain address
     * @param hospitalId Unique hospital identifier
     * @param name Hospital name
     */
    function registerHospital(
        address hospitalAddress,
        string memory hospitalId,
        string memory name
    ) external onlyOwner {
        require(hospitalAddress != address(0), "Invalid hospital address");
        require(bytes(hospitalId).length > 0, "Hospital ID cannot be empty");
        require(!hospitals[hospitalAddress].isVerified, "Hospital already registered");
        
        hospitals[hospitalAddress] = Hospital({
            hospitalAddress: hospitalAddress,
            hospitalId: hospitalId,
            name: name,
            isVerified: true,
            isActive: true
        });
        
        hospitalIdToAddress[hospitalId] = hospitalAddress;
        
        emit HospitalRegistered(hospitalAddress, hospitalId, name);
    }
    
    /**
     * @dev Get emergency details
     * @param emergencyId Emergency identifier
     */
    function getEmergency(string memory emergencyId) 
        external 
        view 
        returns (Emergency memory) 
    {
        return emergencies[emergencyId];
    }
    
    /**
     * @dev Get hospital by address
     * @param hospitalAddress Hospital's blockchain address
     */
    function getHospital(address hospitalAddress) 
        external 
        view 
        returns (Hospital memory) 
    {
        return hospitals[hospitalAddress];
    }
    
    /**
     * @dev Check if emergency exists and is active
     * @param emergencyId Emergency identifier
     */
    function isEmergencyActive(string memory emergencyId) 
        external 
        view 
        returns (bool) 
    {
        return bytes(emergencies[emergencyId].emergencyId).length > 0 && 
               !emergencies[emergencyId].isResolved;
    }
}