import 'game_stats.dart';
import 'team_model.dart';
import 'turn_manager.dart';
import '../utils/ranking.dart';

/// The standings are calculated once from the game's final team snapshot.
class GameResult {
  GameResult._(this.standings, this.winners, this.highlights);

  final List<Team> standings;
  final List<Team> winners;
  final List<GameHighlight> highlights;

  bool get isTie => winners.length > 1;
  String? get winnerName => winners.length == 1 ? winners.single.name : null;
  Team? get winner => winners.length == 1 ? winners.single : null;
  String get tiedWinnerNames => winners.map((team) => team.name).join(' و ');
  List<int> get ranks => denseRanks(standings.map((team) => team.score));

  static GameResult? fromManager(
    TurnManager? manager, {
    Map<String, int> baseline = const {},
    List<GameHighlight> highlights = const [],
  }) => manager == null
      ? null
      : fromTeams([
          for (final team in manager.teams)
            team.copyWith(score: team.score - (baseline[team.id] ?? 0)),
        ], highlights: highlights);

  static GameResult? fromTeams(
    List<Team> teams, {
    List<GameHighlight> highlights = const [],
  }) {
    if (teams.isEmpty) return null;
    final ranked = List<Team>.from(teams)
      ..sort((a, b) => b.score.compareTo(a.score));
    final topScore = ranked.first.score;
    return GameResult._(
      List<Team>.unmodifiable(ranked),
      List<Team>.unmodifiable(ranked.where((team) => team.score == topScore)),
      List<GameHighlight>.unmodifiable(highlights),
    );
  }
}
