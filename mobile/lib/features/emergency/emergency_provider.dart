import 'package:flutter/foundation.dart';
import 'package:medchain_emergency/features/hospital/hospital_model.dart';
import '../../services/emergency_service.dart';

class EmergencyProvider extends ChangeNotifier {
  final EmergencyService _emergencyService = EmergencyService();
  
  bool _isLoading = false;
  bool _isEmergencyActive = false;
  HospitalModel? _matchedHospital; // ✅ Fixed: Changed to HospitalModel
  String? _currentEmergencyId;
  List<HospitalModel> _availableHospitals = []; // ✅ Fixed: Changed to HospitalModel list
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isEmergencyActive => _isEmergencyActive;
  HospitalModel? get matchedHospital => _matchedHospital; // ✅ Fixed: Return HospitalModel
  String? get currentEmergencyId => _currentEmergencyId;
  List<HospitalModel> get availableHospitals => _availableHospitals; // ✅ Fixed: Return HospitalModel list
  String? get error => _error;

  Future<void> createEmergency({
    required double latitude,
    required double longitude,
    required int severity,
    String type = 'general',
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🚨 Creating emergency at: $latitude, $longitude');
      
      // Create emergency using the service
      _currentEmergencyId = await _emergencyService.createEmergency(
        location: 'Current Location',
        severity: severity,
        latitude: latitude,
        longitude: longitude,
      );

      _isEmergencyActive = true;
      
      print('✅ Emergency created: $_currentEmergencyId');
      
      // Start polling for results
      _pollForMatchingResults();
      
    } catch (e) {
      _setError('Nu am putut crea urgența. Te rugăm să încerci din nou sau să suni la 112.');
      print('❌ Emergency creation failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _pollForMatchingResults() async {
    if (_currentEmergencyId == null) return;
    
    try {
      // Simulate waiting for results (since we're using mock data)
      await Future.delayed(const Duration(seconds: 8));
      
      // Get mock hospital result and convert to HospitalModel
      final hospitalMaps = await _emergencyService.getAvailableHospitals();
      if (hospitalMaps.isNotEmpty) {
        // ✅ Fixed: Convert Map to HospitalModel
        _matchedHospital = HospitalModel.fromJson(hospitalMaps.first);
        print('🏥 Hospital matched: ${_matchedHospital!.name}');
        notifyListeners();
      }
      
    } catch (e) {
      print('❌ Error polling for results: $e');
    }
  }

  Future<void> loadAvailableHospitals() async {
    try {
      _setLoading(true);
      final hospitalMaps = await _emergencyService.getAvailableHospitals();
      
      // ✅ Fixed: Convert List<Map> to List<HospitalModel>
      _availableHospitals = hospitalMaps
          .map((hospitalMap) => HospitalModel.fromJson(hospitalMap))
          .toList();
          
    } catch (e) {
      _setError('Nu am putut încărca lista spitalelor.');
      print('❌ Failed to load hospitals: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clearEmergency() {
    _currentEmergencyId = null;
    _matchedHospital = null;
    _isEmergencyActive = false;
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