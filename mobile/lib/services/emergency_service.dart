import 'package:logger/logger.dart';
import 'ocean_service.dart';
import 'web3_service.dart';

class EmergencyService {
  late final Logger _logger;
  late final OceanService _oceanService;
  late final Web3Service _web3Service;

  EmergencyService() {
    _logger = Logger();
    _oceanService = OceanService();
    _web3Service = Web3Service();
  }

  /// Create emergency and start Ocean Protocol matching
  Future<Map<String, dynamic>> createEmergency({
    required String emergencyType,
    required Map<String, dynamic> patientData,
    required Map<String, double> location,
  }) async {
    try {
      _logger.i('🚨 Starting emergency creation flow...');
      
      // Step 1: Generate emergency ID
      final emergencyId = 'emergency_${DateTime.now().millisecondsSinceEpoch}';
      _logger.i('📝 Generated emergency ID: $emergencyId');
      
      String? blockchainTxHash;
      
      // Step 2: Create blockchain record (optional if wallet connected)
      try {
        if (_web3Service.isConnected) {
          _logger.i('💰 Creating blockchain emergency record...');
          blockchainTxHash = await _web3Service.createEmergencyRecord(
            location: '${location['lat']},${location['lng']}',
            severity: patientData['severity']?.toInt() ?? 7,
          );
          _logger.i('✅ Blockchain record created: $blockchainTxHash');
        } else {
          _logger.w('⚠️ Wallet not connected, skipping blockchain step');
        }
      } catch (e) {
        _logger.w('⚠️ Blockchain step failed, continuing with Ocean C2D: $e');
      }
      
      // Step 3: Start Ocean C2D matching
      _logger.i('🌊 Step 2: Starting Ocean C2D matching...');
      
      final hospitalDIDs = await _oceanService.getHospitalDIDs();
      
      final jobId = await _oceanService.startEmergencyMatching(
        hospitalDIDs: hospitalDIDs,
        algorithmDID: 'emergency-matching-algorithm',
        emergencyData: {
          'emergencyId': emergencyId,
          'type': emergencyType,
          'patient': patientData,
          'location': location,
          'severity': patientData['severity'] ?? 7,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      _logger.i('⏳ Step 3: Starting result polling...');
      
      // Step 4: Return emergency info immediately, polling happens in background
      _logger.i('✅ Emergency creation initiated: $emergencyId');
      
      return {
        'emergencyId': emergencyId,
        'jobId': jobId, // This is the CORRECT job ID for polling
        'status': 'processing',
        'blockchainTxHash': blockchainTxHash,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      _logger.e('❌ Emergency creation failed: $e');
      throw Exception('Failed to create emergency: $e');
    }
  }

  /// Poll for results using the CORRECT job ID
  Future<Map<String, dynamic>> pollForResults(String jobId, String emergencyId) async {
    const maxAttempts = 20;
    const pollingInterval = Duration(seconds: 3);
    
    _logger.i('🔄 Polling for results - Emergency: $emergencyId, Job: $jobId');
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _logger.d('🔍 Polling attempt $attempt/$maxAttempts...');
        
        // Use the CORRECT job ID for polling
        final status = await _oceanService.getComputeJobStatus(jobId);
        
        _logger.d('📊 Job status: ${status['status']} (${status['progress'] ?? 0}%)');
        
        if (status['status'] == 'completed') {
          _logger.i('✅ Ocean job completed, getting results...');
          
          final jobResult = await _oceanService.getJobResult(jobId);
          final result = jobResult['result'];
          
          // Parse the results safely
          if (result != null && result['matches'] != null && result['matches'] is List) {
            final matches = result['matches'] as List;
            
            if (matches.isNotEmpty) {
              final bestMatch = matches[0] as Map<String, dynamic>;
              
              _logger.i('🏥 Matched hospital: ${bestMatch['hospitalId']}');
              _logger.i('📊 Match score: ${bestMatch['score']}/100');
              
              // Update blockchain if connected
              try {
                if (_web3Service.isConnected) {
                  await _web3Service.updateEmergencyWithMatch(emergencyId, {
                    'hospital_id': bestMatch['hospitalId'],
                    'match_score': bestMatch['score'],
                  });
                  _logger.i('✅ Blockchain updated with match');
                }
              } catch (e) {
                _logger.w('⚠️ Failed to update blockchain: $e');
              }
              
              _logger.i('🎉 Emergency matching completed successfully!');
              
              return {
                'status': 'completed',
                'emergencyId': emergencyId,
                'jobId': jobId,
                'matchedHospital': bestMatch,
                'allMatches': matches,
                'completedAt': DateTime.now().toIso8601String(),
              };
            }
          }
          
          throw Exception('No hospital matches found in results');
        } else if (status['status'] == 'failed' || status['status'] == 'error') {
          throw Exception('Ocean job failed: ${status['message'] ?? 'Unknown error'}');
        }
        
        // Wait before next poll
        await Future.delayed(pollingInterval);
        
      } catch (e) {
        _logger.e('❌ Error in polling attempt $attempt: $e');
        
        if (attempt == maxAttempts) {
          throw Exception('Polling failed after $maxAttempts attempts: $e');
        }
        
        // Wait before retry
        await Future.delayed(pollingInterval);
      }
    }
    
    throw Exception('Emergency matching timed out after $maxAttempts attempts');
  }

  /// Get job result with proper error handling
  Future<Map<String, dynamic>> getJobResult(String jobId) async {
    try {
      _logger.i('🔍 Getting job result for: $jobId');
      
      final statusData = await _oceanService.getComputeJobStatus(jobId);
      
      if (statusData['status'] != 'completed') {
        _logger.w('⚠️ Job not completed yet: ${statusData['status']}');
        throw Exception('Job not completed yet');
      }

      final result = statusData['result'];
      _logger.i('🏆 Got real Ocean Protocol result');
      
      return {
        'status': 'completed',
        'jobId': jobId,
        'result': result,
        'source': 'ocean_protocol',
      };
      
    } catch (e) {
      _logger.e('❌ Error getting job result: $e');
      throw Exception('Failed to get job result: $e');
    }
  }

  /// Test all services connectivity
  Future<Map<String, bool>> testServices() async {
    try {
      final oceanTest = await _oceanService.testConnection();
      _logger.i('✅ Ocean service test: $oceanTest');
      
      final web3Test = _web3Service.isConnected;
      _logger.i('✅ Web3 service test: $web3Test');
      
      return {
        'ocean': oceanTest,
        'web3': web3Test,
      };
    } catch (e) {
      _logger.e('❌ Service test failed: $e');
      return {
        'ocean': false,
        'web3': false,
      };
    }
  }

  void dispose() {
    _web3Service.dispose();
  }
}