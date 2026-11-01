import 'package:equatable/equatable.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/player_model.dart';

class TeamsState extends Equatable {
  final List<Team> teams;
  final List<Player> players;
  final bool isLoading;

  const TeamsState({
    this.teams = const [],
    this.players = const [],
    this.isLoading = false,
  });

  TeamsState copyWith({
    List<Team>? teams,
    List<Player>? players,
    bool? isLoading,
  }) {
    return TeamsState(
      teams: teams ?? this.teams,
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [teams, players, isLoading];
}

