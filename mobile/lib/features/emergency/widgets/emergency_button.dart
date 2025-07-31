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
        return Container(
          width: double.infinity,
          height: 80,
          child: ElevatedButton(
            onPressed: _isProcessing || emergencyProvider.isLoading 
                ? null 
                : () => _handleEmergencyPress(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
            ),
            child: _isProcessing || emergencyProvider.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isProcessing 
                            ? 'Getting Location...' 
                            : 'Finding Hospitals...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emergency, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'EMERGENCY - ${widget.emergencyType.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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