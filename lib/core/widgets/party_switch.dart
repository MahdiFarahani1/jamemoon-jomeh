import 'package:flutter/material.dart';

import '../../app/di/service_locator.dart';
import '../../app/theme/app_colors.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';

/// A branded, tactile switch widget that produces audio feedback on state changes.
class PartySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;

  const PartySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
  });

  void _handleChanged(bool newValue) {
    if (onChanged == null) return;
    if (sl.isRegistered<AudioService>()) {
      sl<AudioService>().playSwitch(newValue);
    }
    if (sl.isRegistered<HapticsService>()) {
      sl<HapticsService>().lightClick();
    }
    onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged == null ? null : _handleChanged,
      activeColor: activeColor ?? AppColors.accent,
      activeTrackColor:
          activeTrackColor ?? AppColors.accent.withValues(alpha: 0.35),
      inactiveThumbColor: inactiveThumbColor ?? AppColors.textMuted,
      inactiveTrackColor: inactiveTrackColor ?? AppColors.surfaceLight,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
