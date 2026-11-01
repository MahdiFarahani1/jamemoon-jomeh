import 'team_model.dart';

// Fair turn rotation and round management across all party games
class TurnManager {
  final List<Team> teams;
  final int currentTeamIndex;
  final int currentRound;
  final int totalRounds;

  const TurnManager({
    required this.teams,
    this.currentTeamIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 3,
  });

  Team get currentTeam => teams.isNotEmpty ? teams[currentTeamIndex] : const Team(id: 'default', name: 'تیم ۱', colorValue: 0xFFFF5252);

  bool get isGameOver => currentRound > totalRounds;

  TurnManager nextTurn() {
    if (teams.isEmpty) return this;
    final nextIndex = (currentTeamIndex + 1) % teams.length;
    final nextRound = nextIndex == 0 ? currentRound + 1 : currentRound;
    return TurnManager(
      teams: teams,
      currentTeamIndex: nextIndex,
      currentRound: nextRound,
      totalRounds: totalRounds,
    );
  }

  TurnManager updateTeamScore(String teamId, int deltaScore) {
    final updatedList = teams.map((team) {
      if (team.id == teamId) {
        return team.copyWith(score: (team.score + deltaScore).clamp(0, 9999));
      }
      return team;
    }).toList();

    return TurnManager(
      teams: updatedList,
      currentTeamIndex: currentTeamIndex,
      currentRound: currentRound,
      totalRounds: totalRounds,
    );
  }

  List<Team> get rankedTeams {
    final list = List<Team>.from(teams);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }
}
