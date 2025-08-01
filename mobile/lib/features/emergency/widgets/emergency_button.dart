import 'package:flutter/material.dart';
import 'package:medchain_emergency/features/emergency/emergency_provider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyButton extends StatefulWidget {
  final String emergencyType;
  final Map<String, dynamic> patientData;

  const EmergencyButton({
    Key? key,
    required this.emergencyType,
    required this.patientData,
  }) : super(key: key);

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyProvider>(
      builder: (context, emergencyProvider, child) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  spreadRadius: _isProcessing || emergencyProvider.isLoading ? 15 : 5,
                  blurRadius: _isProcessing || emergencyProvider.isLoading ? 25 : 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isProcessing || emergencyProvider.isLoading 
                  ? null 
                  : () => _handleEmergencyPress(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
                elevation: 8,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isProcessing || emergencyProvider.isLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isProcessing 
                              ? 'Getting\nLocation' 
                              : 'Finding\nHospitals',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emergency, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          widget.emergencyType.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEmergencyPress(BuildContext context) async {
    setState(() => _isProcessing = true);
    
    try {
      // Get current location
      final position = await _getCurrentLocation();
      
      final location = {
        'lat': position.latitude,
        'lng': position.longitude,
      };
      
      print('🚨 Creating emergency at: ${position.latitude}, ${position.longitude}');
      
      // Create emergency through provider
      await context.read<EmergencyProvider>().createEmergency(
        emergencyType: widget.emergencyType,
        patientData: widget.patientData,
        location: location,
        onSuccess: (results) {
          // EmergencyProvider now handles navigation
          _handleSuccess(results);
        },
        onError: (error) {
          _showErrorDialog(context, error);
        },
      );
      
    } catch (e) {
      _showErrorDialog(context, e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // No longer need to navigate - EmergencyProvider handles navigation
  // This is just a simple success callback
  void _handleSuccess(Map<String, dynamic> results) {
    print('🎉 Emergency created successfully: ${results['emergencyId']}');
    // No navigation here - EmergencyProvider handles it with the global key
  }

  /// Get current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

void _showErrorDialog(BuildContext context, String error) {
  // Check if the widget is still mounted
  if (!mounted) {
    print('⚠️ Cannot show dialog: widget is not mounted');
    return;
  }
  
  // Use a post-frame callback to ensure we're not in the middle of a build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Check again if still mounted and context is still valid
    if (!mounted || !context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // Use different context name
        title: const Text('Emergency Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  });
}
}