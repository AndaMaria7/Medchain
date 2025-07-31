import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class EmergencyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final AnimationController pulseController;
  final AnimationController breatheController;

  const EmergencyButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.pulseController,
    required this.breatheController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseController, breatheController]),
        builder: (context, child) {
          final pulseValue = pulseController.value;
          final breatheValue = breatheController.value;
          
          return Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Outer glow
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.3 + pulseValue * 0.2),
                  blurRadius: 40 + pulseValue * 20,
                  spreadRadius: 10 + pulseValue * 15,
                ),
                // Inner shadow for depth
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: Offset(0, 8 + breatheValue * 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.emergencyGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(140),
                  onTap: onPressed,
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Icon(
                            Icons.emergency,
                            size: 80,
                            color: Colors.white,
                          ).animate(onPlay: (controller) => controller.repeat())
                              .scale(
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.1, 1.1),
                                duration: 1000.ms,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.1, 1.1),
                                end: const Offset(1.0, 1.0),
                                duration: 1000.ms,
                              ),
                              
                        const SizedBox(height: 16),
                        
                        Text(
                          'URGENȚĂ',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ).animate()
                            .fadeIn(duration: 800.ms)
                            .slideY(begin: 0.3),
                            
                        const SizedBox(height: 8),
                        
                        Text(
                          'EMERGENCY',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ).animate()
                            .fadeIn(delay: 200.ms, duration: 800.ms)
                            .slideY(begin: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}