import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService extends ChangeNotifier {
  // Ethereum client
  late Web3Client _web3client;
  
  // Contract instance
  DeployedContract? _contract;
  
  // User wallet credentials
  EthPrivateKey? _credentials;
  
  // User wallet address
  String? _walletAddress;
  
  // Connection status
  bool _isConnected = false;
  bool _isLoading = false;
  
  // Getters
  String? get walletAddress => _walletAddress;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  
  // RPC URL - Using local Hardhat network
  final String _rpcUrl = "http://127.0.0.1:8545";
  
  // Contract address - will be loaded from assets
  String? _contractAddress;
  
  // Initialize the service
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _web3client = Web3Client(_rpcUrl, http.Client());
    await _loadContractData();
    await _restoreSession();
    
    _isInitialized = true;
    notifyListeners();
  }
  
  // Load contract ABI and address
  Future<void> _loadContractData() async {
    try {
      // Load contract address
      final addressFile = await rootBundle.loadString('assets/contract-address/hospital-registry-address.json');
      final addressJson = jsonDecode(addressFile);
      _contractAddress = addressJson['address'];
      
      // Load contract ABI
      final abiFile = await rootBundle.loadString('assets/contracts/HospitalRegistry.json');
      final abiJson = jsonDecode(abiFile);
      
      // Create contract instance
      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(abiJson['abi']), 'HospitalRegistry'),
        EthereumAddress.fromHex(_contractAddress!),
      );
    } catch (e) {
      print('Error loading contract data: $e');
    }
  }
  
  // Connect wallet using a private key (for demo purposes)
  // In a real app, you would use a more secure method like MetaMask integration
  Future<bool> connectWallet({String? privateKey}) async {
    _setLoading(true);
    
    try {
      // Use a pre-funded Hardhat account for local testing
      // This is the first account created by Hardhat node with 10,000 ETH
      final pk = privateKey ?? '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
      
      // Create credentials from private key
      final credentials = EthPrivateKey.fromHex(pk);
      _credentials = credentials;
      
      // Get wallet address
      final address = await credentials.extractAddress();
      _walletAddress = address.hex;
      
      _isConnected = true;
      await _saveSession(pk);
      notifyListeners();
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('Error connecting wallet: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // No longer using random private key generation
  // User will provide their own private key from MetaMask
  
  // Disconnect wallet
  Future<void> disconnectWallet() async {
    _isConnected = false;
    _walletAddress = null;
    await _clearSession();
    notifyListeners();
  }
  
  // Save session to preferences
  Future<void> _saveSession(String privateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet_address', _walletAddress ?? '');
    await prefs.setString('private_key', privateKey);
  }
  
  // Restore session from preferences
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('wallet_address');
    final savedKey = prefs.getString('private_key');
    
    if (savedAddress != null && savedAddress.isNotEmpty && savedKey != null) {
      await connectWallet(privateKey: savedKey);
    }
  }
  
  // Clear session from preferences
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wallet_address');
    await prefs.remove('private_key');
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Get all hospitals from contract
  Future<Map<String, dynamic>> getAllHospitals() async {
    try {
      if (!_isConnected) {
        return {'success': false, 'error': 'Wallet not connected'};
      }
      
      // Ensure contract is initialized
      if (_contract == null) {
        await _loadContractData();
        if (_contract == null) {
          return {'success': false, 'error': 'Contract not initialized'};
        }
      }
      
      final function = _contract!.function('getAllHospitals');
      final result = await _web3client.call(
        contract: _contract!,
        function: function,
        params: [],
      );
      
      return {
        'success': true,
        'addresses': result[0],
        'capacities': result[1],
      };
    } catch (e) {
      print('Error getting hospitals: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get available hospitals for emergency
  Future<Map<String, dynamic>> getAvailableHospitals(String emergencyType, int minBeds) async {
    try {
      if (!_isConnected) {
        return {'success': false, 'error': 'Wallet not connected'};
      }
      
      // Ensure contract is initialized
      if (_contract == null) {
        await _loadContractData();
        if (_contract == null) {
          return {'success': false, 'error': 'Contract not initialized'};
        }
      }
      
      final function = _contract!.function('getAvailableHospitals');
      final result = await _web3client.call(
        contract: _contract!,
        function: function,
        params: [emergencyType, BigInt.from(minBeds)],
      );
      
      return {
        'success': true,
        'hospitals': result[0],
      };
    } catch (e) {
      print('Error getting available hospitals: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Update hospital capacity
  Future<Map<String, dynamic>> updateCapacity(int icuBeds, int emergencyBeds, int ventilators) async {
    try {
      // Ensure wallet service is initialized
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isConnected) {
        return {'success': false, 'error': 'Wallet not connected'};
      }
      
      // Ensure contract is loaded
      if (_contract == null) {
        await _loadContractData();
        if (_contract == null) {
          return {'success': false, 'error': 'Contract not initialized'};
        }
      }
      
      if (_contract == null) {
        return {'success': false, 'error': 'Contract not initialized'};
      }
      
      final function = _contract!.function('updateCapacity');
      
      // Send transaction
      if (_credentials == null) {
        return {'success': false, 'error': 'Wallet credentials not available'};
      }
      
      final transaction = await _web3client.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: function,
          parameters: [
            BigInt.from(icuBeds),
            BigInt.from(emergencyBeds),
            BigInt.from(ventilators),
          ],
        ),
        chainId: 31337, // Local Hardhat network chain ID
      );
      
      return {'success': true, 'transactionHash': transaction};
    } catch (e) {
      print('Error updating capacity: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Update medical personnel
  Future<Map<String, dynamic>> updateMedicalPersonnel(Map<String, int> personnelCounts) async {
    try {
      // Ensure wallet service is initialized
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isConnected) {
        return {'success': false, 'error': 'Wallet not connected'};
      }
      
      // Ensure contract is loaded
      if (_contract == null) {
        await _loadContractData();
        if (_contract == null) {
          return {'success': false, 'error': 'Contract not initialized'};
        }
      }
      
      // Convert the personnel counts map to lists for the contract call
      final List<String> specialistTypes = [];
      final List<BigInt> counts = [];
      
      personnelCounts.forEach((specialistType, count) {
        specialistTypes.add(specialistType);
        counts.add(BigInt.from(count));
      });
      
      if (_contract == null) {
        return {'success': false, 'error': 'Contract not initialized'};
      }
      
      final function = _contract!.function('updateMedicalPersonnel');
      
      // Send transaction
      if (_credentials == null) {
        return {'success': false, 'error': 'Wallet credentials not available'};
      }
      
      final transaction = await _web3client.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: function,
          parameters: [
            specialistTypes,
            counts,
          ],
        ),
        chainId: 31337, // Local Hardhat network chain ID
      );
      
      return {'success': true, 'transactionHash': transaction};
    } catch (e) {
      print('Error updating medical personnel: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get capacity history for a hospital
  Future<Map<String, dynamic>> getCapacityHistory(String hospitalAddress, int limit) async {
    try {
      if (!_isConnected) {
        return {'success': false, 'error': 'Wallet not connected'};
      }
      
      // Ensure contract is initialized
      if (_contract == null) {
        await _loadContractData();
        if (_contract == null) {
          return {'success': false, 'error': 'Contract not initialized'};
        }
      }
      
      final function = _contract!.function('getCapacityHistory');
      final result = await _web3client.call(
        contract: _contract!,
        function: function,
        params: [EthereumAddress.fromHex(hospitalAddress), BigInt.from(limit)],
      );
      
      return {
        'success': true,
        'history': result[0],
      };
    } catch (e) {
      print('Error getting capacity history: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Register a new hospital (only contract owner can do this)
  Future<Map<String, dynamic>> registerHospital(
    String hospitalAddress, 
    String name, 
    int icuBeds, 
    int emergencyBeds, 
    int ventilators,
    List<String> specializations,
    String location,
    String phoneNumber
  ) async {
    try {
      if (!_isConnected) {
        return {'success': false, 'error': 'Wallet not connected'};
      }
      
      // Ensure contract is initialized
      if (_contract == null) {
        await _loadContractData();
        if (_contract == null) {
          return {'success': false, 'error': 'Contract not initialized'};
        }
      }
      
      final function = _contract!.function('registerHospital');
      
      // Send transaction
      if (_credentials == null) {
        return {'success': false, 'error': 'Wallet credentials not available'};
      }
      
      final transaction = await _web3client.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: function,
          parameters: [
            EthereumAddress.fromHex(hospitalAddress),
            name,
            BigInt.from(icuBeds),
            BigInt.from(emergencyBeds),
            BigInt.from(ventilators),
            specializations,
            location,
            phoneNumber
          ],
        ),
        chainId: 31337, // Local Hardhat network chain ID
      );
      
      return {'success': true, 'transactionHash': transaction};
    } catch (e) {
      print('Error registering hospital: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Verify a hospital (only contract owner can do this)
  Future<Map<String, dynamic>> verifyHospital(String hospitalAddress) async {
    try {
      if (!_isConnected) {
        return {'success': false, 'error': 'Wallet not connected'};
      }
      
      // Ensure contract is initialized
      if (_contract == null) {
        await _loadContractData();
        if (_contract == null) {
          return {'success': false, 'error': 'Contract not initialized'};
        }
      }
      
      final function = _contract!.function('verifyHospital');
      
      // Send transaction
      if (_credentials == null) {
        return {'success': false, 'error': 'Wallet credentials not available'};
      }
      
      final transaction = await _web3client.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: function,
          parameters: [EthereumAddress.fromHex(hospitalAddress)],
        ),
        chainId: 31337, // Local Hardhat network chain ID
      );
      
      return {'success': true, 'transactionHash': transaction};
    } catch (e) {
      print('Error verifying hospital: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Request emergency matching with ML parameters
  Future<Map<String, dynamic>> requestEmergency({
    required String emergencyType, // e.g., cardiac, trauma, pediatric
    required List<String> requiredSpecialists, // e.g., cardiologists, surgeons
    required int urgencyLevel, // 1-10 scale
    String? patientAge,
    String? patientGender,
    Map<String, dynamic>? additionalInfo,
    Map<String, double>? location,
  }) async {
    try {
      // Prepare the emergency data for the ML model
      final emergencyData = {
        'emergencyId': 'emergency_${DateTime.now().millisecondsSinceEpoch}',
        'location': location ?? {'lat': 44.4200, 'lng': 26.1000}, // Default location if not provided
        'severity': urgencyLevel,
        'timestamp': DateTime.now().toIso8601String(),
        'type': emergencyType,
        'requiredSpecialists': requiredSpecialists,
        'patient': {
          'age': patientAge,
          'gender': patientGender,
          ...?additionalInfo,
        }
      };
      
      // Make HTTP request to Ocean compute service
      final response = await http.post(
        Uri.parse('http://localhost:3000/emergency/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientData': emergencyData['patient'],
          'emergencyType': emergencyType,
          'location': emergencyData['location'],
          'requiredSpecialists': requiredSpecialists,
          'urgencyLevel': urgencyLevel
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to start emergency compute: ${response.body}');
      }
      
      final result = jsonDecode(response.body);
      
      // If we have a blockchain connection, we can also record this emergency on-chain
      if (_isConnected) {
        try {
          // Get EmergencyCoordinator contract address
          final emergencyCoordinatorAddress = await _getEmergencyCoordinatorAddress();
          
          if (emergencyCoordinatorAddress != null) {
            // Load EmergencyCoordinator contract ABI
            final abiFile = await rootBundle.loadString('assets/contracts/EmergencyCoordinator.json');
            final abiJson = jsonDecode(abiFile);
            
            // Create contract instance
            final emergencyContract = DeployedContract(
              ContractAbi.fromJson(jsonEncode(abiJson['abi']), 'EmergencyCoordinator'),
              EthereumAddress.fromHex(emergencyCoordinatorAddress),
            );
            
            // Record emergency on-chain
            final recordFunction = emergencyContract.function('recordEmergency');
            await _web3client.sendTransaction(
              _credentials!,
              Transaction.callContract(
                contract: emergencyContract,
                function: recordFunction,
                parameters: [
                  emergencyData['emergencyId'],
                  _walletAddress != null ? EthereumAddress.fromHex(_walletAddress!) : EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
                  emergencyData['location'].toString(),
                  BigInt.from(urgencyLevel),
                  emergencyType,
                  '', // matched hospital ID (will be updated later)
                  BigInt.from(0), // match score (will be updated later)
                  BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
                  false, // isResolved
                  result['jobId'] ?? '', // Ocean job ID
                ],
              ),
              chainId: 31337, // Local Hardhat network chain ID
            );
          }
        } catch (e) {
          print('Warning: Failed to record emergency on blockchain: $e');
          // Continue with the process even if blockchain recording fails
        }
      }
      
      return {
        'success': true,
        'jobId': result['jobId'],
        'status': result['status'],
        'result': result['result'],
      };
    } catch (e) {
      print('Error requesting emergency: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Helper method to get EmergencyCoordinator contract address
  Future<String?> _getEmergencyCoordinatorAddress() async {
    try {
      final addressFile = await rootBundle.loadString('assets/contract-address/emergency-coordinator-address.json');
      final addressJson = jsonDecode(addressFile);
      return addressJson['EmergencyCoordinator'];
    } catch (e) {
      print('Error loading EmergencyCoordinator address: $e');
      return null;
    }
  }
  
  // Poll for emergency job results
  Future<Map<String, dynamic>> pollEmergencyResults(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/job/$jobId'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to poll job: ${response.body}');
      }
      
      final result = jsonDecode(response.body);
      
      return {
        'success': true,
        'status': result['status'],
        'result': result['result'],
        'emergencyData': result['emergencyData'],
      };
    } catch (e) {
      print('Error polling emergency results: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Clean up resources
  @override
  void dispose() {
    _web3client.dispose();
    super.dispose();
  }
}
