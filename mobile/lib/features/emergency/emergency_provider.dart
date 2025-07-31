import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:medchain_emergency/services/emergency_service.dart';

final GlobalKey<NavigatorState> emergencyNavigatorKey = GlobalKey<NavigatorState>();

class EmergencyProvider with ChangeNotifier {
  late final Logger _logger;
  late final EmergencyService _emergencyService;
  
  bool _isLoading = false;
  String? _currentEmergencyId;
  String? _currentJobId;
  Map<String, dynamic>? _emergencyResults;
  String? _error;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get currentEmergencyId => _currentEmergencyId;
  String? get currentJobId => _currentJobId;
  Map<String, dynamic>? get emergencyResults => _emergencyResults;
  String? get error => _error;
  bool get hasResults => _emergencyResults != null;
  
  EmergencyProvider() {
    _logger = Logger();
    _emergencyService = EmergencyService();
  }

  /// Create emergency and handle the full flow
  Future<void> createEmergency({
    required String emergencyType,
    required Map<String, dynamic> patientData,
    required Map<String, double> location,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearResults();
      
      _logger.i('🚨 Creating emergency...');
      
      // Step 1: Create emergency and get job ID
      final emergencyData = await _emergencyService.createEmergency(
        emergencyType: emergencyType,
        patientData: patientData,
        location: location,
      );
      
      _currentEmergencyId = emergencyData['emergencyId'] as String;
      _currentJobId = emergencyData['jobId'] as String;
      
      _logger.i('✅ Emergency created: $_currentEmergencyId');
      _logger.i('🔄 Starting to poll for real Ocean Protocol results...');
      
      // Step 2: Start polling in background
      _pollForMatchingResults(_currentJobId!, _currentEmergencyId!, onSuccess, onError);
      
    } catch (e) {
      _logger.e('❌ Emergency creation failed: $e');
      _setError(e.toString());
      onError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Poll for results and navigate when complete
  Future<void> _pollForMatchingResults(
    String jobId,
    String emergencyId,
    Function(Map<String, dynamic>) onSuccess,
    Function(String) onError,
  ) async {
    try {
      _logger.i('🔄 Polling for job: $jobId');
      
      // Poll for results with CORRECT job ID
      final results = await _emergencyService.pollForResults(jobId, emergencyId);
      
      _emergencyResults = results;
      notifyListeners();
      
      _logger.i('🎉 Results received, navigating to results screen');
      
      // Extract match score for easy access
      double? matchScore;
      if (results['matchedHospital'] != null && results['matchedHospital']['score'] != null) {
        matchScore = (results['matchedHospital']['score'] as num).toDouble();
      }
      
      // Navigate to results screen using the global navigator key
    // This works even if the original widget is unmounted
    if (emergencyNavigatorKey.currentState != null && emergencyNavigatorKey.currentContext != null) {
      // Debug the matched hospital data
      _logger.d('🏥 Matched hospital data: ${results['matchedHospital']}');
      _logger.d('📊 Match score: $matchScore');
      
      // Make sure we have valid data before navigating
      if (results['matchedHospital'] != null) {
        try {
          emergencyNavigatorKey.currentState!.pushNamed(
            '/hospital-results',
            arguments: {
              'emergencyId': results['emergencyId'] ?? '',
              'jobId': results['jobId'] ?? '',
              'matchedHospital': results['matchedHospital'] ?? {},
              'matchScore': matchScore ?? 0.0,
              'allMatches': results['allMatches'] ?? [],
              'emergencyType': results['emergencyType'] ?? 'Emergency',
              'completedAt': results['completedAt'] ?? DateTime.now().toIso8601String(),
            },
          );
        } catch (e) {
          _logger.e('❌ Navigation error: $e');
          _setError('Failed to navigate to hospital results: $e');
        }
      } else {
        _logger.e('❌ No matched hospital data available');
        _setError('No hospital match found');
      }
        
        // Still call onSuccess for any additional handling
        onSuccess(results);
      } else {
        _logger.e('❌ Navigation failed: Navigator not available');
        onError('Navigation failed: Navigator not available');
      }
      
    } catch (e) {
      _logger.e('❌ Polling failed: $e');
      _setError('Failed to get hospital matches: $e');
      onError(e.toString());
    }
  }

  /// Get the best hospital match
  Map<String, dynamic>? get bestHospitalMatch {
    if (_emergencyResults != null && _emergencyResults!['matchedHospital'] != null) {
      return _emergencyResults!['matchedHospital'] as Map<String, dynamic>;
    }
    return null;
  }

  /// Get all hospital matches
  List<Map<String, dynamic>> get allHospitalMatches {
    if (_emergencyResults != null && _emergencyResults!['allMatches'] != null) {
      final matches = _emergencyResults!['allMatches'] as List;
      return matches.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get match score
  double? get matchScore {
    final bestMatch = bestHospitalMatch;
    if (bestMatch != null && bestMatch['score'] != null) {
      return (bestMatch['score'] as num).toDouble();
    }
    return null;
  }

  /// Reset emergency state
  void reset() {
    _currentEmergencyId = null;
    _currentJobId = null;
    _emergencyResults = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Private helper methods
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

  void _clearResults() {
    _emergencyResults = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _emergencyService.dispose();
    super.dispose();
  }
}