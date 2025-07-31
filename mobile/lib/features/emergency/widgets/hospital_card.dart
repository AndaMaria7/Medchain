import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:medchain_emergency/features/hospital/hospital_model.dart';
import '../../../../core/theme/app_theme.dart';

class HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  final VoidCallback onNavigate;
  final VoidCallback onCall;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.onNavigate,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 220,
      borderRadius: 24,
      blur: 15,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.accentGreen.withOpacity(0.1),
          AppTheme.accentGreen.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          AppTheme.accentGreen.withOpacity(0.3),
          AppTheme.accentGreen.withOpacity(0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with hospital info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.hospitalGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spital Recomandat',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hospital.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${hospital.distance?.toStringAsFixed(1) ?? '0.0'} km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Hospital details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.hotel,
                    label: 'Paturi ICU',
                    value: '${hospital.icuBeds}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.emergency,
                    label: 'Paturi UPU',
                    value: '${hospital.emergencyBeds}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: 'Timp așteptare',
                    value: '${hospital.waitTime}min',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.navigation,
                    label: 'Navighează',
                    onPressed: onNavigate,
                    gradient: AppTheme.hospitalGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: 'Sună',
                    onPressed: onCall,
                    gradient: AppTheme.emergencyGradient,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 600.ms).fadeIn();
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required LinearGradient gradient,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}