import 'package:equatable/equatable.dart';

import '../../../../core/models/team_model.dart';
import '../../../../core/models/game_mode.dart';

class TournamentStage {
  final int index;
  final GameInfo game;
  final bool isCompleted;

  const TournamentStage({
    required this.index,
    required this.game,
    this.isCompleted = false,
  });
}

class TournamentState extends Equatable {
  final List<Team> teams;
  final int currentStageIndex;
  final bool isFinished;
  final List<GameInfo> stages;

  const TournamentState({
    this.teams = const [],
    this.currentStageIndex = 0,
    this.isFinished = false,
    this.stages = GameInfo.tournamentGames,
  });

  GameInfo get currentGame =>
      stages[currentStageIndex.clamp(0, stages.length - 1)];

  List<Team> get rankedTeams {
    final list = List<Team>.from(teams);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  TournamentState copyWith({
    List<Team>? teams,
    int? currentStageIndex,
    bool? isFinished,
    List<GameInfo>? stages,
  }) {
    return TournamentState(
      teams: teams ?? this.teams,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      isFinished: isFinished ?? this.isFinished,
      stages: stages ?? this.stages,
    );
  }

  @override
  List<Object?> get props => [teams, currentStageIndex, isFinished, stages];
}
