import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool soundEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  SettingsState copyWith({bool? soundEnabled, bool? vibrationEnabled}) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  List<Object?> get props => [soundEnabled, vibrationEnabled];
}
