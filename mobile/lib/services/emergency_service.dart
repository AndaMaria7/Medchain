import 'package:medchain_emergency/services/ocean_service.dart';
import 'package:medchain_emergency/services/web3_service.dart';
import 'package:logger/logger.dart';

class EmergencyService {
  final Web3Service _web3Service;
  final OceanService _oceanService;
  late final Logger _logger;
  
  EmergencyService({
    Web3Service? web3Service,
    OceanService? oceanService,
  }) : 
    _web3Service = web3Service ?? Web3Service(),
    _oceanService = oceanService ?? OceanService() {
    _logger = Logger();
  }
  
  /// Create emergency with complete flow (works with mock data)
  Future<String> createEmergency({
    required String location,
    required int severity,
    required double latitude,
    required double longitude,
  }) async {
    try {
      _logger.i('🚨 Starting emergency creation flow...');
      
      // Generate emergency ID (without blockchain for now)
      final emergencyId = 'emergency_${DateTime.now().millisecondsSinceEpoch}';
      _logger.i('📝 Generated emergency ID: $emergencyId');
      
      // Step 1: Try blockchain, but continue if it fails
      try {
        if (_web3Service.isConnected) {
          _logger.i('📝 Step 1: Creating blockchain record...');
          await _web3Service.createEmergencyRecord(
            location: location,
            severity: severity,
          );
          _logger.i('✅ Blockchain record created');
        } else {
          _logger.w('⚠️ Wallet not connected, skipping blockchain step');
        }
      } catch (e) {
        _logger.w('⚠️ Blockchain step failed, continuing without it: $e');
      }
      
      // Step 2: Start Ocean compute job for matching (using mock data)
      _logger.i('🌊 Step 2: Starting Ocean C2D matching...');
      final hospitalDIDs = await _getHospitalDIDs();
      
      final jobId = await _oceanService.startEmergencyMatching(
        hospitalDIDs: hospitalDIDs,
        algorithmDID: 'did:op:algorithm-emergency-matching-v1',
        emergencyData: {
          'emergencyId': emergencyId,
          'location': {'lat': latitude, 'lng': longitude},
          'severity': severity,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': _getEmergencyType(severity),
        },
      );
      
      // Step 3: Poll for results and update blockchain (async)
      _logger.i('⏳ Step 3: Starting result polling...');
      _pollForResults(emergencyId, jobId);
      
      _logger.i('✅ Emergency creation initiated: $emergencyId');
      return emergencyId;
      
    } catch (e) {
      _logger.e('❌ Emergency creation failed: $e');
      throw Exception('Failed to create emergency: $e');
    }
  }
  
  /// Poll for Ocean compute results
  Future<Map<String, dynamic>?> _pollForResults(String emergencyId, String jobId) async {
    try {
      _logger.i('🔄 Polling for results - Emergency: $emergencyId, Job: $jobId');
      
      int attempts = 0;
      const maxAttempts = 20; // 2 minutes max
      
      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 6));
        attempts++;
        
        _logger.d('🔍 Polling attempt $attempts/$maxAttempts...');
        
        try {
          final status = await _oceanService.getComputeJobStatus(jobId);
          
          _logger.d('📊 Job status: ${status['status']} (${status['progress']}%)');
          
          if (status['status'] == 'completed') {
            _logger.i('✅ Ocean job completed, getting results...');
            
            // Get the result
            final result = await _oceanService.getJobResult(jobId);
            
            _logger.i('🏥 Matched hospital: ${result['matched_hospital_id']}');
            _logger.i('📊 Match score: ${result['match_score']}/100');
            
            // Try to update blockchain if connected
            try {
              if (_web3Service.isConnected) {
                await _web3Service.updateEmergencyWithMatch(emergencyId, result);
                _logger.i('✅ Blockchain updated with match');
              }
            } catch (e) {
              _logger.w('⚠️ Could not update blockchain: $e');
            }
            
            _logger.i('🎉 Emergency matching completed successfully!');
            return result;
            
          } else if (status['status'] == 'failed') {
            _logger.e('❌ Ocean compute job failed');
            throw Exception('Ocean compute job failed');
            
          } else {
            _logger.d('⏳ Job still processing: ${status['status']} (${status['progress']}%)');
          }
        } catch (e) {
          _logger.w('⚠️ Polling attempt $attempts failed: $e');
          
          if (attempts >= maxAttempts) {
            throw Exception('Polling timed out after $maxAttempts attempts');
          }
          // Continue polling on individual errors
        }
      }
      
      if (attempts >= maxAttempts) {
        _logger.e('⏰ Polling timed out after $maxAttempts attempts');
        throw Exception('Emergency matching timed out');
      }
      
      return null;
      
    } catch (e) {
      _logger.e('❌ Error in result polling: $e');
      return null; // Don't rethrow as this runs async
    }
  }
  
  /// Get emergency type based on severity
  String _getEmergencyType(int severity) {
    if (severity >= 9) return 'critical';
    if (severity >= 7) return 'high';
    if (severity >= 5) return 'medium';
    return 'low';
  }
  
  /// Get hospital DIDs (with fallback)
  Future<List<String>> _getHospitalDIDs() async {
    try {
      return await _oceanService.getHospitalDIDs();
    } catch (e) {
      _logger.e('❌ Failed to get hospital DIDs: $e');
      // Return fallback DIDs
      return [
        'did:op:hospital-bucuresti-urgenta-123',
        'did:op:hospital-cluj-judetean-456',
        'did:op:hospital-regina-maria-789',
      ];
    }
  }
  
  /// Test all services connectivity
  Future<Map<String, bool>> testServices() async {
    final results = <String, bool>{};
    
    try {
      results['ocean'] = await _oceanService.testConnection();
      _logger.i('✅ Ocean service test: ${results['ocean']}');
    } catch (e) {
      results['ocean'] = false;
      _logger.w('⚠️ Ocean service test failed: $e');
    }
    
    try {
      results['web3'] = _web3Service.isConnected;
      _logger.i('✅ Web3 service test: ${results['web3']}');
    } catch (e) {
      results['web3'] = false;
      _logger.w('⚠️ Web3 service test failed: $e');
    }
    
    return results;
  }
  
  /// Get available hospitals (mock data)
  Future<List<Map<String, dynamic>>> getAvailableHospitals() async {
    try {
      // For demo, return mock hospitals
      return [
        {
          'hospital_id': 'spital_urgenta_bucuresti',
          'name': 'Spitalul Universitar de Urgență București',
          'location': 'București, Sector 5',
          'distance_km': 2.1,
          'icu_beds_available': 5,
          'emergency_beds_available': 12,
          'average_wait_time_minutes': 25,
          'reputation_score': 85,
          'has_cardiac_surgery': true,
          'has_trauma_center': true,
        },
        {
          'hospital_id': 'regina_maria_bucuresti',
          'name': 'Spitalul Regina Maria București',
          'location': 'București, Sector 1',
          'distance_km': 1.8,
          'icu_beds_available': 3,
          'emergency_beds_available': 8,
          'average_wait_time_minutes': 15,
          'reputation_score': 78,
          'has_cardiac_surgery': true,
          'has_trauma_center': false,
        },
        {
          'hospital_id': 'spital_judetean_cluj',
          'name': 'Spitalul Județean Cluj',
          'location': 'Cluj-Napoca, Cluj',
          'distance_km': 320.5,
          'icu_beds_available': 8,
          'emergency_beds_available': 15,
          'average_wait_time_minutes': 18,
          'reputation_score': 72,
          'has_cardiac_surgery': true,
          'has_trauma_center': true,
        },
      ];
    } catch (e) {
      _logger.e('❌ Failed to get hospitals: $e');
      return [];
    }
  }
}