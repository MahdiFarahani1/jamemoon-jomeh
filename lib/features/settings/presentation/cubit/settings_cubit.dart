import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/storage_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final StorageService _storageService;

  SettingsCubit(this._storageService)
    : super(
        SettingsState(
          soundEnabled: _storageService.isSoundEnabled,
          vibrationEnabled: _storageService.isVibrationEnabled,
        ),
      );

  Future<void> toggleSound() async {
    final newValue = !state.soundEnabled;
    await _storageService.setSoundEnabled(newValue);
    emit(state.copyWith(soundEnabled: newValue));
  }

  Future<void> toggleVibration() async {
    final newValue = !state.vibrationEnabled;
    await _storageService.setVibrationEnabled(newValue);
    emit(state.copyWith(vibrationEnabled: newValue));
  }

  Future<void> resetAll() async {
    await _storageService.clearAll();
    emit(const SettingsState(soundEnabled: true, vibrationEnabled: true));
  }
}
