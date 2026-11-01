import 'package:flutter/services.dart';
import 'storage_service.dart';

// Haptic feedback controller for suspense and action moments
class HapticsService {
  final StorageService _storageService;

  HapticsService(this._storageService);

  Future<void> lightClick() async {
    if (!_storageService.isVibrationEnabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumBump() async {
    if (!_storageService.isVibrationEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyBoom() async {
    if (!_storageService.isVibrationEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
  }

  Future<void> buzzerFail() async {
    if (!_storageService.isVibrationEnabled) return;
    await HapticFeedback.vibrate();
  }
}
