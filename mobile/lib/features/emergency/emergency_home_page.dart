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
                            isEmergencyActive: provider.isEmergencyActive,
                            isLoading: provider.isLoading,
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
                          
                          const SizedBox(height: 40),
                          
                          // Emergency Button
                          EmergencyButton(
                            onPressed: provider.isLoading ? null : () => _handleEmergencyPress(context, provider),
                            isLoading: provider.isLoading,
                            pulseController: _pulseController,
                            breatheController: _breatheController,
                          ).animate().scale(delay: 400.ms, duration: 800.ms),
                          
                          const SizedBox(height: 40),
                          
                          // Instructions
                          if (!provider.isEmergencyActive && !provider.isLoading)
                            _buildInstructions().animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                          
                          // Loading Message
                          if (provider.isLoading)
                            _buildLoadingMessage().animate().fadeIn().slideY(begin: 0.3),
                          
                          // Emergency Results
                          if (provider.matchedHospital != null)
                            Column(
                              children: [
                                const SizedBox(height: 24),
                                HospitalCard(
                                  hospital: provider.matchedHospital!,
                                  onNavigate: () => _navigateToHospital(provider.matchedHospital!),
                                  onCall: () => _callHospital(provider.matchedHospital!),
                                ).animate().slideY(begin: 0.5, duration: 600.ms),
                                
                                const SizedBox(height: 24),
                                _buildAdditionalActions(provider).animate().fadeIn(delay: 800.ms),
                              ],
                            ),
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
            'Căutăm cel mai bun spital...\nSearching for best hospital...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
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
      ]
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
      
      // Start emergency matching
      await provider.createEmergency(
        latitude: position.latitude,
        longitude: position.longitude,
        severity: 7, // Default high severity
      );
      
    } catch (e) {
      _showErrorDialog(context, 'Eroare: ${e.toString()}');
    }
  }

  void _navigateToHospital(dynamic hospital) {
    // TODO: Open in maps app
  }

  void _callHospital(dynamic hospital) {
    // TODO: Make phone call
  }

  void _showAllHospitals(BuildContext context, EmergencyProvider provider) {
    // TODO: Show all hospitals list
  }

  void _showSettings(BuildContext context) {
    // TODO: Show settings
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