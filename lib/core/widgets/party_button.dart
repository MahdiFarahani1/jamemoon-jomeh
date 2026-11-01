import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/di/service_locator.dart';
import '../services/haptics_service.dart';

// High-tactile 3D Party Game Button (Zero setState)
class PartyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color? shadowColor;
  final Color textColor;
  final double height;
  final double? width;
  final bool isFullWidth;
  final LinearGradient? gradient;

  const PartyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.primary,
    this.shadowColor,
    this.textColor = Colors.white,
    this.height = 54,
    this.width,
    this.isFullWidth = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = shadowColor ?? Color.lerp(color, Colors.black, 0.45)!;
    final isPressedNotifier = ValueNotifier<bool>(false);

    return ValueListenableBuilder<bool>(
      valueListenable: isPressedNotifier,
      builder: (context, isPressed, child) {
        final double pushOffset = isPressed ? 4.0 : 0.0;
        final double shadowDepth = isPressed ? 1.0 : 5.0;

        return SizedBox(
          width: isFullWidth ? double.infinity : width,
          height: height + 6,
          child: GestureDetector(
            onTapDown: onPressed == null
                ? null
                : (_) {
                    isPressedNotifier.value = true;
                    if (sl.isRegistered<HapticsService>()) {
                      sl<HapticsService>().lightClick();
                    }
                  },
            onTapUp: onPressed == null
                ? null
                : (_) {
                    isPressedNotifier.value = false;
                    onPressed?.call();
                  },
            onTapCancel: () => isPressedNotifier.value = false,
            child: Stack(
              children: [
                // 3D Shadow layer
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveShadow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Front surface layer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 60),
                  left: 0,
                  right: 0,
                  top: pushOffset,
                  bottom: shadowDepth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: gradient == null ? color : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: textColor, size: 22),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.buttonText.copyWith(color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

