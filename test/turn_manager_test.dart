import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/models/team_model.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';

void main() {
  group('TurnManager Unit Tests', () {
    final teamA = const Team(id: 't1', name: 'تیم ۱', colorValue: 0xFFFF0000, score: 0);
    final teamB = const Team(id: 't2', name: 'تیم ۲', colorValue: 0xFF0000FF, score: 0);

    test('Initializes with first team and round 1', () {
      final manager = TurnManager(teams: [teamA, teamB], totalRounds: 2);
      expect(manager.currentTeam.id, equals('t1'));
      expect(manager.currentRound, equals(1));
      expect(manager.isGameOver, isFalse);
    });

    test('Rotates to team 2 on nextTurn without advancing round', () {
      final manager = TurnManager(teams: [teamA, teamB], totalRounds: 2).nextTurn();
      expect(manager.currentTeam.id, equals('t2'));
      expect(manager.currentRound, equals(1));
    });

    test('Advances to round 2 after all teams played round 1', () {
      var manager = TurnManager(teams: [teamA, teamB], totalRounds: 2);
      manager = manager.nextTurn(); // teamB
      manager = manager.nextTurn(); // back to teamA, round 2
      expect(manager.currentTeam.id, equals('t1'));
      expect(manager.currentRound, equals(2));
      expect(manager.isGameOver, isFalse);
    });

    test('Correctly signals game over after total rounds completed', () {
      var manager = TurnManager(teams: [teamA, teamB], totalRounds: 1);
      manager = manager.nextTurn(); // teamB
      manager = manager.nextTurn(); // round 2 > totalRounds
      expect(manager.currentRound, equals(2));
      expect(manager.isGameOver, isTrue);
    });

    test('Updates team score correctly and sorts rankedTeams', () {
      var manager = TurnManager(teams: [teamA, teamB], totalRounds: 2);
      manager = manager.updateTeamScore('t1', 5);
      manager = manager.updateTeamScore('t2', 12);

      expect(manager.rankedTeams.first.id, equals('t2'));
      expect(manager.rankedTeams.first.score, equals(12));
      expect(manager.rankedTeams.last.id, equals('t1'));
      expect(manager.rankedTeams.last.score, equals(5));
    });
  });
}
