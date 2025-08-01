import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:medchain_emergency/features/emergency/emergency_provider.dart';
import 'package:medchain_emergency/features/emergency/widgets/emergency_button.dart';
import 'package:medchain_emergency/features/emergency/widgets/hospital_card.dart';
import 'package:medchain_emergency/features/emergency/widgets/status_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

class EmergencyHomePage extends StatefulWidget {
  const EmergencyHomePage({super.key});

  @override
  State<EmergencyHomePage> createState() => _EmergencyHomePageState();
}

class _EmergencyHomePageState extends State<EmergencyHomePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  bool _hasNavigated = false; // Prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _breatheController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Consumer<EmergencyProvider>(
            builder: (context, provider, child) {
              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Urgențe Medicale',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      centerTitle: true,
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => _showSettings(context),
                        icon: const Icon(Icons.settings),
                      ),
                    ],
                  ),
                  
                  // Main Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status Indicator
                          StatusIndicator(
                            isEmergencyActive: provider.isLoading || provider.hasResults,
                            isLoading: provider.isLoading,
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
                          
                          const SizedBox(height: 40),
                          
                          // Emergency Button (only show if not loading and no results)
                          if (!provider.isLoading && !provider.hasResults)
                            EmergencyButton(
  emergencyType: 'general', // Add this
  patientData: {            // Add this
    'severity': 7,
    'symptoms': ['emergency'],
    'age': 30,
    'gender': 'unknown',
  },
).animate().scale(delay: 400.ms, duration: 800.ms),
                          
                          const SizedBox(height: 40),
                          
                          // Instructions
                          if (!provider.isLoading && !provider.hasResults)
                            _buildInstructions().animate().fadeIn(delay: 600.ms),
                          
                          // Loading Message
                          if (provider.isLoading)
                            _buildLoadingMessage().animate().fadeIn().scale(),
                            
                          // Additional Actions (when loading is done but waiting for navigation)
                          if (!provider.isLoading && provider.hasResults && provider.bestHospitalMatch != null)
                            _buildResultsSummary(provider).animate().fadeIn(delay: 800.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 190,
      borderRadius: 20,
      blur: 10,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.accentGreen,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 16,
                color: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Press red button in emergency\n'
              '2. Allow location access\n'
              '3. Get best hospital recommendation',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 130,
      borderRadius: 20,
      blur: 10,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          AppTheme.primaryRed.withOpacity(0.1),
          AppTheme.primaryRed.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          AppTheme.primaryRed.withOpacity(0.3),
          AppTheme.primaryRed.withOpacity(0.1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching for best hospital...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(EmergencyProvider provider) {
    final bestMatch = provider.bestHospitalMatch;
    if (bestMatch == null) return const SizedBox.shrink();
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 360,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Hospital Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bestMatch['name'] ?? 'Unknown Hospital',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            _buildAdditionalActions(provider),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                provider.reset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Start New Emergency'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalActions(EmergencyProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.refresh,
            label: 'Search again',
            onPressed: () => _handleEmergencyPress(context, provider),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.list,
            label: 'Vezi toate\nView all',
            onPressed: () => _showAllHospitals(context, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 80,
        borderRadius: 16,
        blur: 10,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEmergencyPress(BuildContext context, EmergencyProvider provider) async {
    try {
      // Reset navigation flag
      _hasNavigated = false;
      
      // Haptic feedback
      HapticFeedback.heavyImpact();
      
      // Get location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog(context, 'Permisiunea de locație este necesară pentru a găsi spitalul cel mai apropiat.');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog(context, 'Te rugăm să activezi permisiunea de locație în setări.');
        return;
      }
      
      // Get current location
      Position position = await Geolocator.getCurrentPosition();
      
      // Create emergency data
      final patientData = {
        'severity': 7, // High severity
        'symptoms': ['emergency'], // Default symptoms
        'age': 30, // Default age
        'gender': 'unknown', // Default gender
      };
      
      final location = {
        'lat': position.latitude,
        'lng': position.longitude,
      };
      
      // Reset provider state to ensure we can start a new emergency flow
      provider.reset();
      
      // Start emergency matching using the provider method
      await provider.createEmergency(
        emergencyType: 'general', // Default emergency type
        patientData: patientData,
        location: location,
        onSuccess: (results) {
          // Navigate to results screen
          _navigateToResultScreen(provider);
        },
        onError: (error) {
          _showErrorDialog(context, 'Emergency creation failed: $error');
        },
      );
      
    } catch (e) {
      _showErrorDialog(context, 'Eroare: ${e.toString()}');
    }
  }

  Future<void> _navigateToHospital(dynamic hospital) async {
    if (hospital == null) return;
    
    // Get hospital coordinates
    final lat = hospital['latitude'] ?? hospital['location']?['lat'] ?? 0.0;
    final lng = hospital['longitude'] ?? hospital['location']?['lng'] ?? 0.0;
    final name = hospital['name'] ?? 'Hospital';
    
    // Create Google Maps URL
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showErrorDialog(context, 'Could not open maps application');
      }
    }
  }

  Future<void> _callHospital(dynamic hospital) async {
    if (hospital == null) return;
    
    final phone = hospital['phone'] ?? hospital['contact']?['phone'] ?? '';
    if (phone.isEmpty) {
      _showErrorDialog(context, 'No phone number available');
      return;
    }
    
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        _showErrorDialog(context, 'Could not make phone call');
      }
    }
  }

  void _navigateToResultScreen(EmergencyProvider provider) {
    if (_hasNavigated || provider.bestHospitalMatch == null) return;
    
    _hasNavigated = true; // Prevent multiple navigations
    
    // Convert the Map<String, dynamic> to navigation arguments
    final hospitalData = provider.bestHospitalMatch!;
    
    Navigator.of(context).pushNamed(
      '/hospital-results',
      arguments: {
        'emergencyId': provider.currentEmergencyId,
        'jobId': provider.currentJobId,
        'matchedHospital': hospitalData,
        'allMatches': provider.allHospitalMatches,
        'emergencyType': 'general',
        'matchScore': provider.matchScore,
        'completedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  void _showAllHospitals(BuildContext context, EmergencyProvider provider) {
    // Navigate to all hospitals list
    Navigator.of(context).pushNamed(
      '/hospitals-list',
      arguments: {
        'hospitals': provider.allHospitalMatches,
        'emergencyId': provider.currentEmergencyId,
      },
    );
  }

  void _showSettings(BuildContext context) {
    // Navigate to settings screen
    Navigator.of(context).pushNamed('/settings');
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Eroare', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }
}