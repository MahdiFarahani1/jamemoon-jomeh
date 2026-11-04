import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool musicEnabled;

  const SettingsState({
    required this.soundEnabled,
    required this.vibrationEnabled,
    this.musicEnabled = true,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? musicEnabled,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
    );
  }

  @override
  List<Object?> get props => [soundEnabled, vibrationEnabled, musicEnabled];
}
