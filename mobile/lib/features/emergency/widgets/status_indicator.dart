import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/theme/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final bool isEmergencyActive;
  final bool isLoading;
  final String? errorMessage;

  const StatusIndicator({
    super.key,
    required this.isEmergencyActive,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 80,
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.center,
      border: 2,
      linearGradient: _getGradient(),
      borderGradient: _getBorderGradient(),
      child: Row(
        children: [
          const SizedBox(width: 20),
          _buildStatusIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getStatusTitle(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusSubtitle(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    
    if (errorMessage != null) {
      icon = Icons.error_outline;
      color = Colors.red;
    } else if (isLoading) {
      icon = Icons.search;
      color = Colors.orange;
    } else if (isEmergencyActive) {
      icon = Icons.check_circle;
      color = AppTheme.accentGreen;
    } else {
      icon = Icons.health_and_safety;
      color = AppTheme.secondaryBlue;
    }

    Widget iconWidget = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );

    if (isLoading) {
      return iconWidget.animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 2000.ms);
    } else if (isEmergencyActive) {
      return iconWidget.animate()
          .scale(duration: 600.ms)
          .then()
          .shimmer(duration: 1000.ms);
    }

    return iconWidget;
  }

  String _getStatusTitle() {
    if (errorMessage != null) return 'Error';
    if (isLoading) return 'Searching';
    if (isEmergencyActive) return 'Active Emergency';
    return 'System Ready';
  }

  String _getStatusSubtitle() {
    if (errorMessage != null) return 'Try again';
    if (isLoading) return 'Căutăm cel mai bun spital...';
    if (isEmergencyActive) return 'Spital găsit și recomandat';
    return 'Apasă butonul roșu pentru urgență';
  }

  LinearGradient _getGradient() {
    if (errorMessage != null) {
      return LinearGradient(
        colors: [
          Colors.red.withOpacity(0.1),
          Colors.red.withOpacity(0.05),
        ],
      );
    } else if (isLoading) {
      return LinearGradient(
        colors: [
          Colors.orange.withOpacity(0.1),
          Colors.orange.withOpacity(0.05),
        ],
      );
    } else if (isEmergencyActive) {
      return LinearGradient(
        colors: [
          AppTheme.accentGreen.withOpacity(0.1),
          AppTheme.accentGreen.withOpacity(0.05),
        ],
      );
    }
    
    return LinearGradient(
      colors: [
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ],
    );
  }

  LinearGradient _getBorderGradient() {
    Color borderColor;
    
    if (errorMessage != null) {
      borderColor = Colors.red;
    } else if (isLoading) {
      borderColor = Colors.orange;
    } else if (isEmergencyActive) {
      borderColor = AppTheme.accentGreen;
    } else {
      borderColor = Colors.white;
    }

    return LinearGradient(
      colors: [
        borderColor.withOpacity(0.3),
        borderColor.withOpacity(0.1),
      ],
    );
  }
}