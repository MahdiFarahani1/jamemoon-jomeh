import 'package:equatable/equatable.dart';

import '../../data/taboo_card_model.dart';

class TabooState extends Equatable {
  final bool isGameOver;
  final TabooCard? currentCard;
  final int remainingSeconds;
  final int totalSeconds;
  final int correctCount;
  final int foulCount;
  final int skipCount;
  final int roundScore;
  final bool isTimerRunning;
  final bool isRoundOver;
  final bool isPassPhonePhase;
  final String activeTeamName;
  final int activeTeamIndex;
  final int currentRound;
  final int totalRounds;
  final bool isQuickMode;

  const TabooState({
    this.isGameOver = false,
    this.currentCard,
    this.remainingSeconds = 60,
    this.totalSeconds = 60,
    this.correctCount = 0,
    this.foulCount = 0,
    this.skipCount = 0,
    this.roundScore = 0,
    this.isTimerRunning = false,
    this.isRoundOver = false,
    this.isPassPhonePhase = true,
    this.activeTeamName = 'تیم ۱',
    this.activeTeamIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.isQuickMode = false,
  });

  TabooState copyWith({
    bool? isGameOver,
    TabooCard? currentCard,
    int? remainingSeconds,
    int? totalSeconds,
    int? correctCount,
    int? foulCount,
    int? skipCount,
    int? roundScore,
    bool? isTimerRunning,
    bool? isRoundOver,
    bool? isPassPhonePhase,
    String? activeTeamName,
    int? activeTeamIndex,
    int? currentRound,
    int? totalRounds,
    bool? isQuickMode,
  }) {
    return TabooState(
      isGameOver: isGameOver ?? this.isGameOver,
      currentCard: currentCard ?? this.currentCard,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      correctCount: correctCount ?? this.correctCount,
      foulCount: foulCount ?? this.foulCount,
      skipCount: skipCount ?? this.skipCount,
      roundScore: roundScore ?? this.roundScore,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isRoundOver: isRoundOver ?? this.isRoundOver,
      isPassPhonePhase: isPassPhonePhase ?? this.isPassPhonePhase,
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
    currentCard,
    remainingSeconds,
    totalSeconds,
    correctCount,
    foulCount,
    skipCount,
    roundScore,
    isTimerRunning,
    isRoundOver,
    isPassPhonePhase,
    activeTeamName,
    activeTeamIndex,
    currentRound,
    totalRounds,
    isQuickMode,
  ];
}
