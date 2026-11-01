import 'package:equatable/equatable.dart';
import '../../data/hot_potato_topic_model.dart';

class HotPotatoState extends Equatable {
  final HotPotatoTopic? currentTopic;
  final int elapsedSeconds;
  final int hiddenBombDuration;
  final bool isExploded;
  final bool isTicking;
  final int turnPassCount;
  final String holdingTeamOrPlayer;
  final String? loserName;
  final int currentRound;
  final int totalRounds;
  final bool isQuickMode;

  const HotPotatoState({
    this.currentTopic,
    this.elapsedSeconds = 0,
    this.hiddenBombDuration = 30,
    this.isExploded = false,
    this.isTicking = false,
    this.turnPassCount = 0,
    this.holdingTeamOrPlayer = 'تیم ۱',
    this.loserName,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.isQuickMode = false,
  });

  HotPotatoState copyWith({
    HotPotatoTopic? currentTopic,
    int? elapsedSeconds,
    int? hiddenBombDuration,
    bool? isExploded,
    bool? isTicking,
    int? turnPassCount,
    String? holdingTeamOrPlayer,
    String? loserName,
    int? currentRound,
    int? totalRounds,
    bool? isQuickMode,
  }) {
    return HotPotatoState(
      currentTopic: currentTopic ?? this.currentTopic,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hiddenBombDuration: hiddenBombDuration ?? this.hiddenBombDuration,
      isExploded: isExploded ?? this.isExploded,
      isTicking: isTicking ?? this.isTicking,
      turnPassCount: turnPassCount ?? this.turnPassCount,
      holdingTeamOrPlayer: holdingTeamOrPlayer ?? this.holdingTeamOrPlayer,
      loserName: loserName ?? this.loserName,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      isQuickMode: isQuickMode ?? this.isQuickMode,
    );
  }

  // Tension ratio from 0.0 to 1.0 (approaching explosion)
  double get tensionRatio =>
      (elapsedSeconds / hiddenBombDuration).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
        currentTopic,
        elapsedSeconds,
        hiddenBombDuration,
        isExploded,
        isTicking,
        turnPassCount,
        holdingTeamOrPlayer,
        loserName,
        currentRound,
        totalRounds,
        isQuickMode,
      ];
}

