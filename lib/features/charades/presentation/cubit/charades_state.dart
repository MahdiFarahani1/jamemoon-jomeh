import 'package:equatable/equatable.dart';

import '../../data/charades_word_model.dart';

class CharadesState extends Equatable {
  final bool isGameOver;
  final CharadesWord? currentWord;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isTimerRunning;
  final bool isPassPhonePhase;
  final bool isSecretRevealed;
  final bool isRoundOver;
  final int roundScore;
  final int correctCount;
  final int skipCount;
  final String activeTeamName;
  final int activeTeamIndex;
  final int currentRound;
  final int totalRounds;
  final bool isQuickMode;

  const CharadesState({
    this.isGameOver = false,
    this.currentWord,
    this.remainingSeconds = 60,
    this.totalSeconds = 60,
    this.isTimerRunning = false,
    this.isPassPhonePhase = true,
    this.isSecretRevealed = false,
    this.isRoundOver = false,
    this.roundScore = 0,
    this.correctCount = 0,
    this.skipCount = 0,
    this.activeTeamName = 'تیم ۱',
    this.activeTeamIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.isQuickMode = false,
  });

  CharadesState copyWith({
    bool? isGameOver,
    CharadesWord? currentWord,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isTimerRunning,
    bool? isPassPhonePhase,
    bool? isSecretRevealed,
    bool? isRoundOver,
    int? roundScore,
    int? correctCount,
    int? skipCount,
    String? activeTeamName,
    int? activeTeamIndex,
    int? currentRound,
    int? totalRounds,
    bool? isQuickMode,
  }) {
    return CharadesState(
      isGameOver: isGameOver ?? this.isGameOver,
      currentWord: currentWord ?? this.currentWord,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isPassPhonePhase: isPassPhonePhase ?? this.isPassPhonePhase,
      isSecretRevealed: isSecretRevealed ?? this.isSecretRevealed,
      isRoundOver: isRoundOver ?? this.isRoundOver,
      roundScore: roundScore ?? this.roundScore,
      correctCount: correctCount ?? this.correctCount,
      skipCount: skipCount ?? this.skipCount,
      activeTeamName: activeTeamName ?? this.activeTeamName,
      activeTeamIndex: activeTeamIndex ?? this.activeTeamIndex,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      isQuickMode: isQuickMode ?? this.isQuickMode,
    );
  }

  @override
  List<Object?> get props => [
    isGameOver,
    currentWord,
    remainingSeconds,
    totalSeconds,
    isTimerRunning,
    isPassPhonePhase,
    isSecretRevealed,
    isRoundOver,
    roundScore,
    correctCount,
    skipCount,
    activeTeamName,
    activeTeamIndex,
    currentRound,
    totalRounds,
    isQuickMode,
  ];
}
