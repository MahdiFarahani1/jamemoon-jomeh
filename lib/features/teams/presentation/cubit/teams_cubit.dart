import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/services/storage_service.dart';
import 'teams_state.dart';

// Cubit for managing party game teams and players (No setState)
class TeamsCubit extends Cubit<TeamsState> {
  final StorageService _storageService;

  TeamsCubit(this._storageService) : super(const TeamsState()) {
    loadSavedTeams();
  }

  void loadSavedTeams() {
    final savedTeamsData = _storageService.getSavedTeams();
    final savedPlayersData = _storageService.getSavedPlayers();

    if (savedTeamsData.isEmpty) {
      // Default initial 2 teams for instant fun
      final defaultTeams = [
        const Team(id: 'team_1', name: 'تیم پلنگ‌ها', colorValue: 0xFFFF5252, iconKey: 'flash'),
        const Team(id: 'team_2', name: 'تیم عقاب‌ها', colorValue: 0xFF448AFF, iconKey: 'star'),
      ];
      emit(state.copyWith(teams: defaultTeams, players: const []));
      _persistTeams(defaultTeams);
    } else {
      final teams = savedTeamsData.map((e) => Team.fromJson(e)).toList();
      final players = savedPlayersData.map((e) => Player.fromJson(e)).toList();
      emit(state.copyWith(teams: teams, players: players));
    }
  }

  void addTeam({required String name, required int colorValue}) {
    final newTeam = Team(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'تیم ${state.teams.length + 1}' : name.trim(),
      colorValue: colorValue,
    );
    final updatedTeams = List<Team>.from(state.teams)..add(newTeam);
    emit(state.copyWith(teams: updatedTeams));
    _persistTeams(updatedTeams);
  }

  void removeTeam(String teamId) {
    if (state.teams.length <= 2) return; // Keep at least 2 teams
    final updatedTeams = state.teams.where((t) => t.id != teamId).toList();
    final updatedPlayers = state.players.map((p) {
      if (p.teamId == teamId) return p.copyWith(teamId: null);
      return p;
    }).toList();

    emit(state.copyWith(teams: updatedTeams, players: updatedPlayers));
    _persistTeams(updatedTeams);
    _persistPlayers(updatedPlayers);
  }

  void addPlayer({required String name, String? teamId}) {
    if (name.trim().isEmpty) return;
    final newPlayer = Player(
      id: 'player_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      teamId: teamId,
    );
    final updatedPlayers = List<Player>.from(state.players)..add(newPlayer);
    emit(state.copyWith(players: updatedPlayers));
    _persistPlayers(updatedPlayers);
  }

  void removePlayer(String playerId) {
    final updatedPlayers = state.players.where((p) => p.id != playerId).toList();
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
        return t.copyWith(score: (t.score + deltaScore).clamp(0, 9999));
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

