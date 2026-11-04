import 'player_model.dart';
import 'team_model.dart';

/// Adapts named people to the existing fair turn/score engine.
List<Team> playerTeams(List<Player> players) {
  const colors = [
    0xFFEF5350,
    0xFF42A5F5,
    0xFF66BB6A,
    0xFFFFCA28,
    0xFFAB47BC,
    0xFFFF7043,
  ];
  return [
    for (var index = 0; index < players.length; index++)
      if (players[index].name.trim().isNotEmpty)
        Team(
          id: 'player_${players[index].id}',
          name: players[index].name.trim(),
          colorValue: colors[index % colors.length],
          iconKey: 'person',
        ),
  ];
}

/// Every named member receives one performing turn in each visible round.
Map<String, int> teamTurnCounts(List<Team> teams, List<Player> players) => {
  for (final team in teams)
    team.id: players
        .where((player) => player.teamId == team.id)
        .length
        .clamp(1, 1000),
};

class PlayerTurnAssignment {
  const PlayerTurnAssignment({required this.performer, required this.guesser});

  final String performer;
  final String guesser;

  static PlayerTurnAssignment? forTeam({
    required List<Team> teams,
    required List<Player> players,
    required String teamName,
    required int round,
    int seed = 0,
  }) {
    final teamIndex = teams.indexWhere((team) => team.name == teamName);
    if (teamIndex < 0) return null;
    final members = players
        .where((player) => player.teamId == teams[teamIndex].id)
        .toList();
    if (members.isEmpty) return null;
    final performerIndex =
        (seed.abs() + teamIndex + round - 1) % members.length;
    final guesserIndex = members.length == 1
        ? performerIndex
        : (performerIndex + 1) % members.length;
    return PlayerTurnAssignment(
      performer: members[performerIndex].name,
      guesser: members[guesserIndex].name,
    );
  }
}
