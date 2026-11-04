import 'dart:math';

import 'team_model.dart';

// Fair turn rotation and round management across all party games
class TurnManager {
  final List<Team> teams;
  final int currentTeamIndex;
  final int currentRound;
  final int totalRounds;
  final List<int> turnOrder;
  final int currentTurnIndex;

  const TurnManager({
    required this.teams,
    this.currentTeamIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.turnOrder = const [],
    this.currentTurnIndex = 0,
  });

  factory TurnManager.randomStart({
    required List<Team> teams,
    int totalRounds = 3,
    Random? random,
    Map<String, int> turnsByTeamId = const {},
  }) {
    final randomized = List<Team>.of(teams);
    if (randomized.length > 1) randomized.shuffle(random);
    final counts = [
      for (final team in randomized)
        (turnsByTeamId[team.id] ?? 1).clamp(1, 1000),
    ];
    final order = <int>[];
    final longest = counts.fold<int>(0, max);
    for (var turn = 0; turn < longest; turn++) {
      for (var team = 0; team < randomized.length; team++) {
        if (turn < counts[team]) order.add(team);
      }
    }
    return TurnManager(
      teams: randomized,
      totalRounds: totalRounds,
      turnOrder: order,
      currentTeamIndex: order.isEmpty ? 0 : order.first,
    );
  }

  Team get currentTeam => teams.isNotEmpty
      ? teams[currentTeamIndex]
      : const Team(id: 'default', name: 'تیم ۱', colorValue: 0xFFFF5252);

  bool get isGameOver => currentRound > totalRounds;

  bool get isFinalTurn =>
      currentRound == totalRounds &&
      (turnOrder.isEmpty
          ? currentTeamIndex == teams.length - 1
          : currentTurnIndex == turnOrder.length - 1);

  /// One-based appearance number for the current team in the full match.
  /// This rotates performers inside a team without changing the visible round.
  int get currentTeamTurnNumber {
    if (turnOrder.isEmpty) return currentRound;
    final perRound = turnOrder
        .where((index) => index == currentTeamIndex)
        .length;
    final inThisRound = turnOrder
        .take(currentTurnIndex + 1)
        .where((index) => index == currentTeamIndex)
        .length;
    return (currentRound - 1) * perRound + inThisRound;
  }

  TurnManager nextTurn() {
    if (teams.isEmpty) return this;
    if (turnOrder.isNotEmpty) {
      final nextTurnIndex = currentTurnIndex + 1;
      final startsNextRound = nextTurnIndex >= turnOrder.length;
      final normalizedTurnIndex = startsNextRound ? 0 : nextTurnIndex;
      return TurnManager(
        teams: teams,
        currentTeamIndex: turnOrder[normalizedTurnIndex],
        currentRound: startsNextRound ? currentRound + 1 : currentRound,
        totalRounds: totalRounds,
        turnOrder: turnOrder,
        currentTurnIndex: normalizedTurnIndex,
      );
    }
    final nextIndex = (currentTeamIndex + 1) % teams.length;
    final nextRound = nextIndex == 0 ? currentRound + 1 : currentRound;
    return TurnManager(
      teams: teams,
      currentTeamIndex: nextIndex,
      currentRound: nextRound,
      totalRounds: totalRounds,
      turnOrder: turnOrder,
      currentTurnIndex: currentTurnIndex,
    );
  }

  /// Rotate the holder without consuming a round. Used by the bomb game.
  TurnManager nextTeam() {
    if (teams.isEmpty) return this;
    return TurnManager(
      teams: teams,
      currentTeamIndex: (currentTeamIndex + 1) % teams.length,
      currentRound: currentRound,
      totalRounds: totalRounds,
      turnOrder: turnOrder,
      currentTurnIndex: currentTurnIndex,
    );
  }

  TurnManager withCurrentTeamIndex(int index) {
    if (teams.isEmpty || index < 0 || index >= teams.length) return this;
    return TurnManager(
      teams: teams,
      currentTeamIndex: index,
      currentRound: currentRound,
      totalRounds: totalRounds,
      turnOrder: turnOrder,
      currentTurnIndex: currentTurnIndex,
    );
  }

  TurnManager updateTeamScore(String teamId, int deltaScore) {
    final updatedList = teams.map((team) {
      if (team.id == teamId) {
        return team.copyWith(
          score: (team.score + deltaScore).clamp(-9999, 9999),
        );
      }
      return team;
    }).toList();

    return TurnManager(
      teams: updatedList,
      currentTeamIndex: currentTeamIndex,
      currentRound: currentRound,
      totalRounds: totalRounds,
      turnOrder: turnOrder,
      currentTurnIndex: currentTurnIndex,
    );
  }

  List<Team> get rankedTeams {
    final list = List<Team>.from(teams);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }
}
