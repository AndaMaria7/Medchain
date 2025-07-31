import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medchain_emergency/features/emergency/emergency_home_page.dart';
import 'package:medchain_emergency/features/emergency/emergency_provider.dart';
import 'package:medchain_emergency/features/hospital/hospital_provider.dart';
import 'package:medchain_emergency/features/hospital/hospital_admin_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0f0f23),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MedChainApp());
}

class MedChainApp extends StatelessWidget {
  const MedChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
      ],
      child: MaterialApp(
        title: 'MedChain Emergency',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AppRouter(),
        routes: {
          '/emergency': (context) => const EmergencyHomePage(),
          '/hospital-admin': (context) => const HospitalAdminPage(),
        },
      ).animate().fadeIn(duration: 800.ms),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppTheme.emergencyGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        size: 60,
                        color: Colors.white,
                      ),
                    ).animate()
                        .scale(delay: 200.ms, duration: 600.ms)
                        .then()
                        .shimmer(duration: 1000.ms),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      'MedChain',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Emergency Response System',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  ],
                ),
                
                const SizedBox(height: 80),
                
                // Action Buttons
                Column(
                  children: [
                    _buildActionButton(
                      context,
                      title: 'EMERGENCY',
                      subtitle: 'Press for immediate help',
                      gradient: AppTheme.emergencyGradient,
                      icon: Icons.emergency,
                      onTap: () => Navigator.pushNamed(context, '/emergency'),
                    ).animate().slideX(delay: 800.ms, begin: -0.3),
                    
                    const SizedBox(height: 24),
                    
                    _buildActionButton(
                      context,
                      title: 'HOSPITAL ADMIN',
                      subtitle: 'Update capacity',
                      gradient: AppTheme.hospitalGradient,
                      icon: Icons.local_hospital,
                      onTap: () => Navigator.pushNamed(context, '/hospital-admin'),
                    ).animate().slideX(delay: 1000.ms, begin: 0.3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}