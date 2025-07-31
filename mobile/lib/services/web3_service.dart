import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class Web3Service {
  static const String _rpcUrl = 'https://sepolia.infura.io/v3/4f6eb33f101d42cc8864b31847e1205f';
  static const String _chainId = '11155111'; // Sepolia
  
  late final Web3Client _web3Client;
  late final Logger _logger;
  
  String? _currentAddress;
  Web3App? _wcClient;
  SessionData? _currentSession;

  // Contract addresses (deploy your contracts and update these)
  static const String _emergencyCoordinatorAddress = '0x1234567890123456789012345678901234567890'; // Placeholder
  static const String _hospitalRegistryAddress = '0x0987654321098765432109876543210987654321'; // Placeholder

  Web3Service() {
    _web3Client = Web3Client(_rpcUrl, Client());
    _logger = Logger();
    _initializeWalletConnect(); // Sets up _wcClient instance
  }

  String? get currentAddress => _currentAddress;
  bool get isConnected => _currentAddress != null && _currentSession != null;

  void _initializeWalletConnect() {
    try {
      _wcClient = Web3App(
        core: Core(
          projectId: '4f6eb33f101d42cc8864b31847e1205f', // Get from WalletConnect Cloud
        ),
        metadata: const PairingMetadata(
          name: 'MedChain Emergency',
          description: 'Emergency hospital coordination system',
          url: 'https://medchain.app',
          icons: ['https://medchain.app/icon.png'],
        ),
      );
      _logger.i('🔗 WalletConnect initialized');
    } catch (e) {
      _logger.e('❌ WalletConnect initialization failed: $e');
    }
  }

  /// Connect wallet (MetaMask, Trust Wallet, etc.)
  Future<String?> connectWallet() async {
    if (_wcClient == null) {
    _logger.e('WalletConnect not initialized');
      throw Exception('WalletConnect not initialized');
    }

    try {
      // Ensure WalletConnect core is initialized
      await _wcClient!.init();

      _logger.i('🔗 Connecting wallet...');

      final ConnectResponse connectResponse = await _wcClient!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:$_chainId'],
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
              'eth_signTypedData',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final Uri? uri = connectResponse.uri;
      _logger.d('🔗 WalletConnect URI: $uri');

      // Attempt to open the wallet app automatically with the URI (Metamask, etc.)
      if (uri != null) {
        final Uri launchUri = uri;
        try {
          if (await canLaunchUrl(launchUri)) {
            await launchUrl(launchUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {/* ignore deep link errors */}
      }

      // Wait for connection
      _currentSession = await connectResponse.session.future;
      
      if (_currentSession?.namespaces['eip155']?.accounts.isNotEmpty == true) {
        _currentAddress = _currentSession!.namespaces['eip155']!.accounts.first.split(':').last;
        _logger.i('✅ Wallet connected: $_currentAddress');
        return _currentAddress;
      } else {
        throw Exception('No accounts found in session');
      }

    } catch (e) {
      _logger.e('❌ Wallet connection failed: $e');
      throw Exception('Failed to connect wallet: $e');
    }
  }

  /// Disconnect wallet
  Future<void> disconnectWallet() async {
    try {
      if (_wcClient != null && _currentSession != null) {
        await _wcClient!.disconnectSession(
          topic: _currentSession!.topic,
          reason: const WalletConnectError(
            code: 6000,
            message: 'User disconnected',
          ),
        );
      }
      
      _currentAddress = null;
      _currentSession = null;
      _logger.i('👋 Wallet disconnected');
    } catch (e) {
      _logger.e('❌ Error disconnecting wallet: $e');
    }
  }

  /// Create emergency record on blockchain
  Future<String> createEmergencyRecord({
    required String location,
    required int severity,
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      _logger.i('🚨 Creating emergency on blockchain...');

      final contract = DeployedContract(
        ContractAbi.fromJson(_getEmergencyCoordinatorAbi(), 'EmergencyCoordinator'),
        EthereumAddress.fromHex(_emergencyCoordinatorAddress),
      );

      final createEmergencyFunction = contract.function('createEmergency');
      
      final transaction = Transaction.callContract(
        contract: contract,
        function: createEmergencyFunction,
        parameters: [location, BigInt.from(severity)],
        from: EthereumAddress.fromHex(_currentAddress!),
        gasPrice: EtherAmount.inWei(BigInt.from(2000000000)), // 2 gwei
      );

      final txHash = await _sendTransaction(transaction);
      
      _logger.i('✅ Emergency created: $txHash');
      return txHash;

    } catch (e) {
      _logger.e('❌ Failed to create emergency: $e');
      throw Exception('Failed to create emergency: $e');
    }
  }

  /// Update emergency with matched hospital
  Future<String> updateEmergencyWithMatch(String emergencyId, Map<String, dynamic> matchedHospital) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      _logger.i('🏥 Updating emergency with matched hospital...');

      final contract = DeployedContract(
        ContractAbi.fromJson(_getEmergencyCoordinatorAbi(), 'EmergencyCoordinator'),
        EthereumAddress.fromHex(_emergencyCoordinatorAddress),
      );

      final updateEmergencyFunction = contract.function('updateEmergencyMatch');
      
      final transaction = Transaction.callContract(
        contract: contract,
        function: updateEmergencyFunction,
        parameters: [
          emergencyId,
          matchedHospital['hospital_id'] ?? '',
          BigInt.from(matchedHospital['match_score']?.toInt() ?? 0),
        ],
        from: EthereumAddress.fromHex(_currentAddress!),
        gasPrice: EtherAmount.inWei(BigInt.from(2000000000)), // 2 gwei
      );

      final txHash = await _sendTransaction(transaction);
      
      _logger.i('✅ Emergency updated: $txHash');
      return txHash;

    } catch (e) {
      _logger.e('❌ Failed to update emergency: $e');
      throw Exception('Failed to update emergency: $e');
    }
  }

  /// Update hospital capacity on blockchain
  Future<String> updateHospitalCapacity({
    required int icuBeds,
    required int emergencyBeds,
    required int ventilators,
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      _logger.i('🏥 Updating hospital capacity on blockchain...');

      final contract = DeployedContract(
        ContractAbi.fromJson(_getHospitalRegistryAbi(), 'HospitalRegistry'),
        EthereumAddress.fromHex(_hospitalRegistryAddress),
      );

      final updateCapacityFunction = contract.function('updateCapacity');
      
      final transaction = Transaction.callContract(
        contract: contract,
        function: updateCapacityFunction,
        parameters: [
          BigInt.from(icuBeds),
          BigInt.from(emergencyBeds),
          BigInt.from(ventilators),
        ],
        from: EthereumAddress.fromHex(_currentAddress!),
        gasPrice: EtherAmount.inWei(BigInt.from(2000000000)), // 2 gwei
      );

      final txHash = await _sendTransaction(transaction);
      
      _logger.i('✅ Hospital capacity updated: $txHash');
      return txHash;

    } catch (e) {
      _logger.e('❌ Failed to update capacity: $e');
      throw Exception('Failed to update hospital capacity: $e');
    }
  }

  /// Get hospital capacity from blockchain
  Future<Map<String, dynamic>> getHospitalCapacity(String hospitalAddress) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(_getHospitalRegistryAbi(), 'HospitalRegistry'),
        EthereumAddress.fromHex(_hospitalRegistryAddress),
      );

      final getHospitalFunction = contract.function('hospitals');
      
      final result = await _web3Client.call(
        contract: contract,
        function: getHospitalFunction,
        params: [EthereumAddress.fromHex(hospitalAddress)],
      );

      return {
        'icuBeds': (result[1] as BigInt).toInt(),
        'emergencyBeds': (result[2] as BigInt).toInt(),
        'ventilators': (result[3] as BigInt).toInt(),
        'lastUpdated': DateTime.fromMillisecondsSinceEpoch(
          (result[4] as BigInt).toInt() * 1000,
        ),
        'isVerified': result[5] as bool,
      };

    } catch (e) {
      _logger.e('❌ Failed to get hospital capacity: $e');
      throw Exception('Failed to get hospital capacity: $e');
    }
  }

  /// Send transaction via WalletConnect
  Future<String> _sendTransaction(Transaction transaction) async {
    if (_wcClient == null || _currentSession == null) {
      throw Exception('WalletConnect not properly initialized');
    }

    try {
      final result = await _wcClient!.request(
        topic: _currentSession!.topic,
        chainId: 'eip155:$_chainId',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [
            {
              'from': transaction.from?.hex,
              'to': transaction.to?.hex,
              'data': transaction.data,
              'gas': transaction.maxGas != null ? _intToHex(transaction.maxGas!) : null,
              'gasPrice': transaction.gasPrice != null ? _bigIntToHex(transaction.gasPrice!.getInWei) : null,
              'value': transaction.value != null ? _bigIntToHex(transaction.value!.getInWei) : '0x0',
            }
          ],
        ),
      );

      return result as String;

    } catch (e) {
      _logger.e('❌ Transaction failed: $e');
      throw Exception('Transaction failed: $e');
    }
  }

  // Helper to convert int to hex with 0x prefix
  String _intToHex(int value) => '0x${value.toRadixString(16)}';

  // Helper to convert BigInt to hex with 0x prefix
  String _bigIntToHex(BigInt value) => '0x${value.toRadixString(16)}';

  /// Get transaction receipt
  Future<TransactionReceipt?> getTransactionReceipt(String txHash) async {
    try {
      return await _web3Client.getTransactionReceipt(txHash);
    } catch (e) {
      _logger.e('❌ Failed to get transaction receipt: $e');
      return null;
    }
  }

  /// Get current ETH balance
  Future<EtherAmount> getBalance([String? address]) async {
    final addr = address ?? _currentAddress;
    if (addr == null) throw Exception('No address provided');
    
    return await _web3Client.getBalance(EthereumAddress.fromHex(addr));
  }

  // Contract ABIs (simplified - you'll need to add your actual contract ABIs)
  String _getEmergencyCoordinatorAbi() {
    return '''[
      {
        "inputs": [
          {"name": "location", "type": "string"},
          {"name": "severity", "type": "uint256"}
        ],
        "name": "createEmergency",
        "outputs": [{"name": "", "type": "bytes32"}],
        "type": "function"
      },
      {
        "inputs": [
          {"name": "emergencyId", "type": "string"},
          {"name": "hospitalId", "type": "string"},
          {"name": "matchScore", "type": "uint256"}
        ],
        "name": "updateEmergencyMatch",
        "outputs": [],
        "type": "function"
      }
    ]''';
  }

  String _getHospitalRegistryAbi() {
    return '''[
      {
        "inputs": [
          {"name": "icuBeds", "type": "uint256"},
          {"name": "emergencyBeds", "type": "uint256"},
          {"name": "ventilators", "type": "uint256"}
        ],
        "name": "updateCapacity",
        "outputs": [],
        "type": "function"
      },
      {
        "inputs": [{"name": "", "type": "address"}],
        "name": "hospitals",
        "outputs": [
          {"name": "name", "type": "string"},
          {"name": "icuBeds", "type": "uint256"},
          {"name": "emergencyBeds", "type": "uint256"},
          {"name": "ventilators", "type": "uint256"},
          {"name": "lastUpdated", "type": "uint256"},
          {"name": "verified", "type": "bool"}
        ],
        "type": "function"
      }
    ]''';
  }

  void dispose() {
    _web3Client.dispose();
  }
}