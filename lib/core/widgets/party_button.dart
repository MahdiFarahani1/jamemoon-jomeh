import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/di/service_locator.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';

class PartyButton extends StatefulWidget {
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
  State<PartyButton> createState() => _PartyButtonState();
}

class _PartyButtonState extends State<PartyButton> {
  final ValueNotifier<bool> _pressed = ValueNotifier(false);
  @override
  void dispose() {
    _pressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final shadow =
        widget.shadowColor ?? Color.lerp(widget.color, Colors.black, .45)!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveTextColor =
        widget.textColor == Colors.white &&
            ThemeData.estimateBrightnessForColor(widget.color) ==
                Brightness.light
        ? AppColors.background
        : widget.textColor;
    return ValueListenableBuilder<bool>(
      valueListenable: _pressed,
      builder: (context, pressed, _) {
        final down = enabled && pressed;
        return Semantics(
          button: true,
          enabled: enabled,
          child: SizedBox(
            width: widget.isFullWidth ? double.infinity : widget.width,
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: shadow,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: shadow, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: AnimatedContainer(
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 90),
                    transform: Matrix4.translationValues(0, down ? 2 : 0, 0),
                    decoration: BoxDecoration(
                      color: widget.gradient == null ? widget.color : null,
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: enabled
                            ? () {
                                if (sl.isRegistered<AudioService>()) {
                                  sl<AudioService>().playTap();
                                }
                                widget.onPressed!();
                              }
                            : null,
                        onHighlightChanged: (value) {
                          if (mounted) _pressed.value = value;
                          if (value && sl.isRegistered<HapticsService>()) {
                            sl<HapticsService>().lightClick();
                          }
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: widget.height < 48 ? 48 : widget.height,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.icon != null &&
                                      constraints.maxWidth >= 120) ...[
                                    Icon(
                                      widget.icon,
                                      color: effectiveTextColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      widget.label,
                                      style: AppTypography.buttonText.copyWith(
                                        color: effectiveTextColor,
                                        fontSize: constraints.maxWidth < 120
                                            ? 13
                                            : 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
