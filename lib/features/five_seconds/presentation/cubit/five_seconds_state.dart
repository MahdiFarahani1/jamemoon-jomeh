import 'package:equatable/equatable.dart';
import '../../data/five_seconds_model.dart';

class FiveSecondsState extends Equatable {
  final FiveSecondsQuestion? currentQuestion;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isTimerRunning;
  final bool isCountdownFinished;
  final bool isPassPhonePhase;
  final int roundScore;
  final int successCount;
  final int failCount;
  final String activeTeamName;
  final int activeTeamIndex;
  final int currentRound;
  final int totalRounds;
  final bool isQuickMode;

  const FiveSecondsState({
    this.currentQuestion,
    this.remainingSeconds = 5,
    this.totalSeconds = 5,
    this.isTimerRunning = false,
    this.isCountdownFinished = false,
    this.isPassPhonePhase = true,
    this.roundScore = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.activeTeamName = 'تیم ۱',
    this.activeTeamIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.isQuickMode = false,
  });

  FiveSecondsState copyWith({
    FiveSecondsQuestion? currentQuestion,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isTimerRunning,
    bool? isCountdownFinished,
    bool? isPassPhonePhase,
    int? roundScore,
    int? successCount,
    int? failCount,
    String? activeTeamName,
    int? activeTeamIndex,
    int? currentRound,
    int? totalRounds,
    bool? isQuickMode,
  }) {
    return FiveSecondsState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isCountdownFinished: isCountdownFinished ?? this.isCountdownFinished,
      isPassPhonePhase: isPassPhonePhase ?? this.isPassPhonePhase,
      roundScore: roundScore ?? this.roundScore,
      successCount: successCount ?? this.successCount,
      failCount: failCount ?? this.failCount,
      activeTeamName: activeTeamName ?? this.activeTeamName,
      activeTeamIndex: activeTeamIndex ?? this.activeTeamIndex,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      isQuickMode: isQuickMode ?? this.isQuickMode,
    );
  }

  @override
  List<Object?> get props => [
        currentQuestion,
        remainingSeconds,
        totalSeconds,
        isTimerRunning,
        isCountdownFinished,
        isPassPhonePhase,
        roundScore,
        successCount,
        failCount,
        activeTeamName,
        activeTeamIndex,
        currentRound,
        totalRounds,
        isQuickMode,
      ];
}

