import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/models/participant_roster.dart';
import 'package:flutter_application_1/core/models/player_model.dart';
import 'package:flutter_application_1/core/models/team_model.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';

void main() {
  group('TurnManager Unit Tests', () {
    final teamA = const Team(
      id: 't1',
      name: 'تیم ۱',
      colorValue: 0xFFFF0000,
      score: 0,
    );
    final teamB = const Team(
      id: 't2',
      name: 'تیم ۲',
      colorValue: 0xFF0000FF,
      score: 0,
    );

    test('Initializes with first team and round 1', () {
      final manager = TurnManager(teams: [teamA, teamB], totalRounds: 2);
      expect(manager.currentTeam.id, equals('t1'));
      expect(manager.currentRound, equals(1));
      expect(manager.isGameOver, isFalse);
    });

    test('Rotates to team 2 on nextTurn without advancing round', () {
      final manager = TurnManager(
        teams: [teamA, teamB],
        totalRounds: 2,
      ).nextTurn();
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

    test('fresh games randomize the starter without losing a team', () {
      final starters = <String>{};
      for (var seed = 0; seed < 20; seed++) {
        final manager = TurnManager.randomStart(
          teams: [teamA, teamB],
          totalRounds: 2,
          random: Random(seed),
        );
        starters.add(manager.currentTeam.id);
        expect(manager.teams.map((team) => team.id).toSet(), {'t1', 't2'});
      }
      expect(starters, {'t1', 't2'});
    });

    test('player assignment uses the session seed and rotates fairly', () {
      const players = [
        Player(id: 'p1', name: 'علی', teamId: 't1'),
        Player(id: 'p2', name: 'سارا', teamId: 't1'),
        Player(id: 'p3', name: 'رضا', teamId: 't1'),
      ];
      final first = PlayerTurnAssignment.forTeam(
        teams: [teamA, teamB],
        players: players,
        teamName: teamA.name,
        round: 1,
        seed: 11,
      )!;
      final second = PlayerTurnAssignment.forTeam(
        teams: [teamA, teamB],
        players: players,
        teamName: teamA.name,
        round: 2,
        seed: 11,
      )!;
      expect(first.performer, isNot(second.performer));
      expect(first.performer, isNot(first.guesser));
    });

    test('one visible round gives every team member one performing turn', () {
      const players = [
        Player(id: 'a1', name: 'آوا', teamId: 't1'),
        Player(id: 'a2', name: 'آراد', teamId: 't1'),
        Player(id: 'a3', name: 'آناهیتا', teamId: 't1'),
        Player(id: 'b1', name: 'بهار', teamId: 't2'),
        Player(id: 'b2', name: 'بابک', teamId: 't2'),
      ];
      var manager = TurnManager.randomStart(
        teams: [teamA, teamB],
        totalRounds: 1,
        random: Random(4),
        turnsByTeamId: teamTurnCounts([teamA, teamB], players),
      );
      final performers = <String, Set<String>>{'t1': {}, 't2': {}};
      var turns = 0;

      while (!manager.isGameOver) {
        final assignment = PlayerTurnAssignment.forTeam(
          teams: manager.teams,
          players: players,
          teamName: manager.currentTeam.name,
          round: manager.currentTeamTurnNumber,
          seed: 12,
        )!;
        performers[manager.currentTeam.id]!.add(assignment.performer);
        turns++;
        manager = manager.nextTurn();
      }

      expect(turns, 5);
      expect(performers['t1'], {'آوا', 'آراد', 'آناهیتا'});
      expect(performers['t2'], {'بهار', 'بابک'});
    });
  });
}
