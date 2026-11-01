import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

// Styled Card Container for Party Game Elements
class PartyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const PartyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.borderRadius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? AppColors.surfaceBorder,
      width: 1.5,
    );

    final boxDecoration = BoxDecoration(
      color: gradient == null ? (backgroundColor ?? AppColors.surface) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: boxDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );
  }
}

