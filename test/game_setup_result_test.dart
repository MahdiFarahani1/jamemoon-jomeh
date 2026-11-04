import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/game_result.dart';
import 'package:flutter_application_1/core/models/game_setup_config.dart';
import 'package:flutter_application_1/core/models/player_model.dart';
import 'package:flutter_application_1/core/models/team_model.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/haptics_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/core/widgets/game_lifecycle_guard.dart';
import 'package:flutter_application_1/features/charades/data/charades_repository.dart';
import 'package:flutter_application_1/features/charades/data/charades_word_model.dart';
import 'package:flutter_application_1/features/charades/presentation/cubit/charades_cubit.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';

class _FakeCharadesRepository implements CharadesRepository {
  _FakeCharadesRepository(this._words);
  final List<CharadesWord> _words;
  int _index = 0;

  @override
  Future<void> loadWords() async {}

  @override
  CharadesWord getNextWord({int? filterPoints, String category = 'all'}) {
    final word = _words[_index % _words.length];
    _index++;
    return word;
  }

  @override
  bool get isLoaded => true;

  @override
  bool hasCategory(String category) => true;

  @override
  CharadesWord? findById(String id) {
    for (final word in _words) {
      if (word.id == id) return word;
    }
    return null;
  }

  @override
  int get totalWords => _words.length;
}

void main() {
  const first = Team(id: 'a', name: 'اول', colorValue: 0xff000000);
  const second = Team(id: 'b', name: 'دوم', colorValue: 0xffffffff);
  const third = Team(id: 'c', name: 'سوم', colorValue: 0xff555555);
  const members = [
    Player(id: '1', name: 'الف', teamId: 'a'),
    Player(id: '2', name: 'ب', teamId: 'a'),
    Player(id: '3', name: 'پ', teamId: 'b'),
    Player(id: '4', name: 'ت', teamId: 'b'),
  ];

  test('winner is determined by final score including penalties', () {
    final manager = TurnManager(teams: [first, second])
        .updateTeamScore('a', -2)
        .updateTeamScore('b', 1);
    final result = GameResult.fromManager(manager)!;
    expect(result.winnerName, 'دوم');
    expect(result.standings.map((team) => team.score), [1, -2]);
    expect(result.isTie, isFalse);
  });

  test('ties have two winners and no unique winner name', () {
    final result = GameResult.fromTeams([
      first.copyWith(score: 3),
      second.copyWith(score: 3),
    ])!;
    expect(result.isTie, isTrue);
    expect(result.winners.length, 2);
    expect(result.winnerName, isNull);
    expect(result.tiedWinnerNames, 'اول و دوم');
  });

  test('three-team tie reports all winners and combined name', () {
    final result = GameResult.fromTeams([
      first.copyWith(score: 5),
      second.copyWith(score: 5),
      third.copyWith(score: 5),
    ])!;
    expect(result.isTie, isTrue);
    expect(result.winners.length, 3);
    expect(result.tiedWinnerNames, 'اول و دوم و سوم');
  });

  test('negative scores correctly crown the least negative team', () {
    final result = GameResult.fromTeams([
      first.copyWith(score: -1),
      second.copyWith(score: -4),
    ])!;
    expect(result.isTie, isFalse);
    expect(result.winnerName, 'اول');
    expect(result.standings.first.score, -1);
  });

  test(
    'stage winner uses points earned in this game, not tournament total',
    () {
      final manager = TurnManager(
        teams: [first.copyWith(score: 12), second.copyWith(score: 11)],
      );
      final result = GameResult.fromManager(
        manager,
        baseline: {'a': 10, 'b': 4},
      )!;
      expect(result.winnerName, 'دوم');
      expect(result.standings.map((team) => team.score), [7, 2]);
    },
  );

  test('bomb handoff does not consume a round', () {
    final manager = TurnManager(teams: [first, second], totalRounds: 5);
    final afterTwoPasses = manager.nextTeam().nextTeam();
    expect(afterTwoPasses.currentRound, 1);
    expect(afterTwoPasses.currentTeamIndex, 0);
  });

  test('only timed games expose duration choices', () {
    for (final game in ['taboo', 'charades', 'drawing']) {
      expect(GameSetupConfig.hasRoundDuration(game), isTrue);
      expect(
        GameSetupConfig.fromArguments(game, {
          'roundSeconds': 90,
          'totalRounds': 7,
        }).toArguments(),
        {'roundSeconds': 90, 'totalRounds': 7},
      );
    }
    for (final game in ['five_seconds', 'hot_potato', 'decoder']) {
      expect(GameSetupConfig.hasRoundDuration(game), isFalse);
      expect(
        GameSetupConfig.fromArguments(game, {'roundSeconds': 90}).roundSeconds,
        isNull,
      );
    }
    expect(GameSetupConfig.hasRounds('decoder'), isFalse);
    expect(GameSetupConfig.hasRounds('taboo'), isTrue);
  });

  test('one round and named-player mode are supported', () {
    expect(GameSetupConfig.allowedRounds, contains(1));
    final config = GameSetupConfig.fromArguments('hot_potato', {
      'totalRounds': 1,
      'participationMode': 'players',
    });
    expect(config.totalRounds, 1);
    expect(config.participationMode, GameParticipationMode.players);
    expect(config.toArguments(), {
      'totalRounds': 1,
      'participationMode': 'players',
    });
  });

  test('required team members are validated before start', () {
    expect(
      GameSetupRequirements.validate('taboo', [first, second], members),
      isNull,
    );
    expect(
      GameSetupRequirements.validate('taboo', [
        first,
        second,
      ], members.take(3).toList()),
      isNotNull,
    );
    expect(
      GameSetupRequirements.validate('hot_potato', [first, second], []),
      isNull,
    );
    expect(
      GameSetupRequirements.validate('decoder', [first, second], members),
      isNull,
    );
    expect(
      GameSetupRequirements.validate('decoder', [first, second], []),
      'تیم «اول» به دست‌کم 2 عضو نیاز دارد.',
    );
  });

  testWidgets('final screen shows a tie and both team scores', (tester) async {
    final result = GameResult.fromTeams([
      first.copyWith(score: 2),
      second.copyWith(score: 2),
    ])!;
    await tester.pumpWidget(
      MaterialApp(
        home: GameCompletionView(gameKey: 'taboo', result: result),
      ),
    );
    await tester.pump();
    expect(find.text('بازی مساوی شد!'), findsOneWidget);
    expect(find.textContaining('2 امتیاز'), findsNWidgets(2));
    expect(find.text('رقابت شانه به شانه بین اول و دوم!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'final screen shows decisive single winner with congratulations',
    (tester) async {
      final result = GameResult.fromTeams([
        first.copyWith(score: 5),
        second.copyWith(score: 2),
      ])!;
      await tester.pumpWidget(
        MaterialApp(
          home: GameCompletionView(gameKey: 'charades', result: result),
        ),
      );
      await tester.pump();
      expect(find.text('قهرمان: اول'), findsOneWidget);
      expect(find.text('تبریک به اول برای کسب پیروزی درخشان!'), findsOneWidget);
      expect(find.textContaining('5 امتیاز'), findsOneWidget);
      expect(find.textContaining('2 امتیاز'), findsOneWidget);
      expect(find.text('تیم پیروز'), findsOneWidget);
      expect(find.text('ادامه'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('Charades onCorrect awards the actual word difficulty points', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    if (!sl.isRegistered<StorageService>()) {
      sl.registerSingleton<StorageService>(storage);
    }
    if (!sl.isRegistered<AudioService>()) {
      sl.registerSingleton<AudioService>(AudioService(storage));
    }
    if (!sl.isRegistered<HapticsService>()) {
      sl.registerSingleton<HapticsService>(HapticsService(storage));
    }

    final words = [
      const CharadesWord(id: '1', word: 'آ', category: 'ساده', points: 1),
      const CharadesWord(
        id: '2',
        word: 'گربه ترساندن',
        category: 'متوسط',
        points: 2,
      ),
      const CharadesWord(id: '3', word: 'کتاب', category: 'دشوار', points: 3),
    ];
    final repo = _FakeCharadesRepository(words);
    final teamsCubit = TeamsCubit(storage);
    final cubit = CharadesCubit(
      repository: repo,
      teamsCubit: teamsCubit,
      setup: const GameSetupConfig(roundSeconds: 60, totalRounds: 3),
    );

    cubit.startRound();
    expect(cubit.state.currentWord?.points, 1);
    cubit.onCorrect();
    expect(cubit.state.roundScore, 1);
    expect(cubit.state.correctCount, 1);

    expect(cubit.state.currentWord?.points, 2);
    cubit.onCorrect();
    expect(cubit.state.roundScore, 3); // 1 + 2 = 3
    expect(cubit.state.correctCount, 2);

    expect(cubit.state.currentWord?.points, 3);
    cubit.onCorrect();
    expect(cubit.state.roundScore, 6); // 3 + 3 = 6
    expect(cubit.state.correctCount, 3);

    final activeTeam = cubit.result?.standings.firstWhere(
      (t) => t.id == cubit.state.activeTeamIndex.toString() || t.score > 0,
    );
    expect(activeTeam?.score, 6);
  });
}
