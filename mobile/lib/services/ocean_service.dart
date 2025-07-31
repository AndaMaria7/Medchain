import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class OceanService {
  // Base URL can be overridden at compile-time via:
  // flutter run --dart-define=OCEAN_BACKEND_URL=http://<host>:<port>
  static const String _baseUrl = String.fromEnvironment(
    'OCEAN_BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );
  late final Logger _logger;

  OceanService() {
    _logger = Logger();
  }

  /// Start emergency matching using real Ocean Protocol compute
  Future<String> startEmergencyMatching({
    required List<String> hospitalDIDs, // Keep interface compatible
    required String algorithmDID,       // Keep interface compatible  
    required Map<String, dynamic> emergencyData,
  }) async {
    try {
      _logger.i('🌊 Starting REAL Ocean C2D job...');
      
      // Extract patient data and emergency type from emergencyData
      final patientData = emergencyData['patient'] ?? emergencyData;
      final emergencyType = emergencyData['type'] ?? emergencyData['emergency_type'] ?? 'general';
      final location = emergencyData['location'];

      final response = await http.post(
        Uri.parse('$_baseUrl/emergency/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientData': patientData,
          'emergencyType': emergencyType,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobId = data['jobId'] as String;
        
        _logger.i('✅ Real Ocean job started: $jobId');
        return jobId;
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Server error: ${error['error']}');
      }
      
    } catch (e) {
      _logger.e('❌ Real Ocean job failed: $e');
      throw Exception('Ocean compute job failed: $e');
    }
  }

  /// Get compute job status from real backend
  Future<Map<String, dynamic>> getComputeJobStatus(String jobId) async {
    try {
      _logger.d('📊 Getting REAL job status for: $jobId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/job/$jobId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['status'],
          'jobId': data['id'],
          'progress': data['status'] == 'completed' ? 100 : 50,
          'result': data['result'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'not_found',
          'jobId': jobId,
          'progress': 0,
        };
      } else {
        throw Exception('Failed to get job status');
      }
      
    } catch (e) {
      _logger.e('❌ Error getting job status: $e');
      throw Exception('Failed to get job status: $e');
    }
  }

  /// Get compute job result - now returns real Ocean Protocol results
  Future<Map<String, dynamic>> getJobResult(String jobId) async {
    try {
      _logger.i('📊 Getting REAL job result for: $jobId');
      
      final statusData = await getComputeJobStatus(jobId);
      
      if (statusData['status'] != 'completed') {
        throw Exception('Job not completed yet');
      }

      // The result comes from your Ocean Protocol compute
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

  /// Get hospital DIDs (can still be mocked or from your JSON files)
  Future<List<String>> getHospitalDIDs() async {
    // This can read from your hospital_assets.json or be hardcoded
    return [
      'did:op:hospital-bucuresti-urgenta-123',
      'did:op:hospital-cluj-judetean-456', 
      'did:op:hospital-regina-maria-789',
    ];
  }

  /// Test connection to real backend
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      if (response.statusCode == 200) {
        _logger.i('✅ Real Ocean service connection successful');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('❌ Connection test failed: $e');
      return false;
    }
  }
}