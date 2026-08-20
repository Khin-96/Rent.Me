import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/property_model.dart';

class PropertyMarker extends StatelessWidget {
  final PropertyModel property;
  final bool isSelected;
  final VoidCallback onTap;

  const PropertyMarker({
    super.key,
    required this.property,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 10,
          vertical: isSelected ? 7 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.markerSelected : AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x401A73E8),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.home_rounded,
                color: AppColors.white,
                size: 12,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              Formatters.currencyShort(property.rentAmount),
              style: TextStyle(
                color: AppColors.white,
                fontSize: isSelected ? 13 : 12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pulsing user location indicator
class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: false);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return Opacity(
                  opacity: (1.4 - _pulseAnimation.value) * 0.5,
                  child: Container(
                    width: 14 + (_pulseAnimation.value * 16),
                    height: 14 + (_pulseAnimation.value * 16),
                    decoration: BoxDecoration(
                      color: AppColors.locationPulse.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            // Core dot
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.locationPulse,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
