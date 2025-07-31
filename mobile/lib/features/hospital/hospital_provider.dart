import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:medchain_emergency/features/hospital/hospital_capacity_model.dart';
import 'package:medchain_emergency/services/web3_service.dart';


class HospitalProvider extends ChangeNotifier {
  final Web3Service _web3Service = Web3Service();
  final Dio _dio = Dio();
  
  bool _isLoading = false;
  bool _isConnected = false;
  String? _hospitalAddress;
  HospitalCapacityModel? _currentCapacity;
  String? _error;
  List<String> _recentTransactions = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get hospitalAddress => _hospitalAddress;
  HospitalCapacityModel? get currentCapacity => _currentCapacity;
  String? get error => _error;
  List<String> get recentTransactions => _recentTransactions;

  Future<void> connectWallet() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _web3Service.connectWallet();
      _hospitalAddress = _web3Service.currentAddress;
      _isConnected = true;
      
      // Load current capacity
      await _loadCurrentCapacity();
      
      print('✅ Wallet connected: $_hospitalAddress');
      
    } catch (e) {
      _setError('Nu am putut conecta wallet-ul. Te rugăm să verifici MetaMask.');
      print('❌ Wallet connection failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCapacity({
    required int icuBeds,
    required int emergencyBeds,
    required int ventilators,
  }) async {
    if (!_isConnected) {
      _setError('Te rugăm să conectezi wallet-ul mai întâi.');
      return;
    }

    try {
      _setLoading(true);
      _clearError();
      
      // Update capacity via smart contract
      final txHash = await _web3Service.updateHospitalCapacity(
        icuBeds: icuBeds,
        emergencyBeds: emergencyBeds,
        ventilators: ventilators,
      );
      
      // Update local model
      _currentCapacity = HospitalCapacityModel(
        icuBeds: icuBeds,
        emergencyBeds: emergencyBeds,
        ventilators: ventilators,
        lastUpdated: DateTime.now(),
        txHash: txHash,
      );
      
      _recentTransactions.insert(0, txHash);
      if (_recentTransactions.length > 10) {
        _recentTransactions = _recentTransactions.take(10).toList();
      }
      
      print('✅ Capacity updated: $txHash');
      
    } catch (e) {
      _setError('Nu am putut actualiza capacitatea. Verifică conexiunea la blockchain.');
      print('❌ Capacity update failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadCurrentCapacity() async {
    if (!_isConnected || _hospitalAddress == null) return;
    
    try {
      final capacity = await _web3Service.getHospitalCapacity(_hospitalAddress!);
      _currentCapacity = HospitalCapacityModel.fromBlockchain(capacity);
    } catch (e) {
      print('⚠️ Could not load current capacity: $e');
    }
  }

  void disconnect() {
    _isConnected = false;
    _hospitalAddress = null;
    _currentCapacity = null;
    _recentTransactions.clear();
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}