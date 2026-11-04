import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/team_model.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/services/storage_service.dart';
import 'teams_state.dart';

// Cubit for managing party game teams and players (No setState)
class TeamsCubit extends Cubit<TeamsState> {
  final StorageService _storageService;
  int _idSequence = 0;

  static const _defaultTeams = [
    Team(
      id: 'team_1',
      name: 'تیم پلنگ‌ها',
      colorValue: 0xFFFF5252,
      iconKey: 'flash',
    ),
    Team(
      id: 'team_2',
      name: 'تیم عقاب‌ها',
      colorValue: 0xFF448AFF,
      iconKey: 'star',
    ),
  ];

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idSequence++}';

  TeamsCubit(this._storageService) : super(const TeamsState()) {
    loadSavedTeams();
  }

  void loadSavedTeams() {
    final savedTeamsData = _storageService.getSavedTeams();
    final savedPlayersData = _storageService.getSavedPlayers();

    final savedTeams = savedTeamsData.map((e) => Team.fromJson(e)).toList();
    final teams = [
      ...savedTeams.take(2),
      if (savedTeams.isEmpty) ..._defaultTeams,
      if (savedTeams.length == 1) _defaultTeams[1],
    ];
    final validIds = teams.map((team) => team.id).toSet();
    final savedPlayers = savedPlayersData
        .map((e) => Player.fromJson(e))
        .toList();
    final players = [
      for (final player in savedPlayers)
        validIds.contains(player.teamId)
            ? player
            : player.copyWith(teamId: null),
    ];
    emit(state.copyWith(teams: teams, players: players));
    if (savedTeams.length != 2) _persistTeams(teams);
    if (savedPlayers.any(
      (player) => player.teamId != null && !validIds.contains(player.teamId),
    )) {
      _persistPlayers(players);
    }
  }

  void updateTeam(
    String teamId, {
    required String name,
    required int colorValue,
    required String iconKey,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || !state.teams.any((team) => team.id == teamId)) {
      return;
    }
    final updatedTeams = [
      for (final team in state.teams)
        team.id == teamId
            ? team.copyWith(
                name: trimmedName,
                colorValue: colorValue,
                iconKey: iconKey,
              )
            : team,
    ];
    emit(state.copyWith(teams: updatedTeams));
    _persistTeams(updatedTeams);
  }

  void addPlayer({required String name, String? teamId}) {
    if (name.trim().isEmpty) return;
    final newPlayer = Player(
      id: _newId('player'),
      name: name.trim(),
      teamId: teamId,
    );
    final updatedPlayers = List<Player>.from(state.players)..add(newPlayer);
    emit(state.copyWith(players: updatedPlayers));
    _persistPlayers(updatedPlayers);
  }

  void removePlayer(String playerId) {
    final updatedPlayers = state.players
        .where((p) => p.id != playerId)
        .toList();
    emit(state.copyWith(players: updatedPlayers));
    _persistPlayers(updatedPlayers);
  }

  void resetAllScores() {
    final resetTeams = state.teams.map((t) => t.copyWith(score: 0)).toList();
    emit(state.copyWith(teams: resetTeams));
    _persistTeams(resetTeams);
  }

  void updateTeamScore(String teamId, int deltaScore) {
    final updatedTeams = state.teams.map((t) {
      if (t.id == teamId) {
        return t.copyWith(score: (t.score + deltaScore).clamp(-9999, 9999));
      }
      return t;
    }).toList();
    emit(state.copyWith(teams: updatedTeams));
    _persistTeams(updatedTeams);
  }

  void _persistTeams(List<Team> teams) {
    _storageService.saveTeams(teams.map((t) => t.toJson()).toList());
  }

  void _persistPlayers(List<Player> players) {
    _storageService.savePlayers(players.map((p) => p.toJson()).toList());
  }
}
