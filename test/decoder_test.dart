import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/models/team_model.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/features/decoder/data/decoder_repository.dart';
import 'package:flutter_application_1/features/decoder/presentation/cubit/decoder_cubit.dart';
import 'package:flutter_application_1/features/decoder/presentation/cubit/decoder_state.dart';

const _words = <String>[
  'آب',
  'آتش',
  'آسمان',
  'آینه',
  'ابر',
  'انار',
  'باد',
  'باران',
  'برف',
  'بهار',
  'پاییز',
  'پرنده',
  'پل',
  'دریا',
  'درخت',
  'دوچرخه',
  'رودخانه',
  'روز',
  'زنبور',
  'ستاره',
  'ساعت',
  'سیب',
  'شمع',
  'شهر',
  'صبح',
  'عقاب',
  'قلم',
  'کوه',
  'ماه',
  'مداد',
  'موزه',
  'نان',
  'نقاشی',
  'هواپیما',
  'یخ',
];

class _WordBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData(0);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      jsonEncode(_words);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late DecoderRepository repository;
  final first = Team(id: 'first', name: 'تیم اول', colorValue: 1);
  final second = Team(id: 'second', name: 'تیم دوم', colorValue: 2);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
    repository = DecoderRepository(
      storageService: storage,
      random: Random(17),
      bundle: _WordBundle(),
    );
  });

  test('deals 25 unique words with equal team counts', () async {
    final game = await repository.newGame(first, second);
    expect(game.cards, hasLength(25));
    expect(
      game.cards.map((card) => normalizeDecoderWord(card.word)).toSet(),
      hasLength(25),
    );
    expect(
      game.cards.where((card) => card.role == DecoderRole.team0),
      hasLength(DecoderRepository.teamWordCount),
    );
    expect(
      game.cards.where((card) => card.role == DecoderRole.team1),
      hasLength(DecoderRepository.teamWordCount),
    );
    expect(
      game.cards.where((card) => card.role == DecoderRole.neutral),
      hasLength(DecoderRepository.neutralWordCount),
    );
    expect(
      game.cards.where((card) => card.role == DecoderRole.hazard),
      hasLength(1),
    );
  });

  test(
    'normalizes Persian and Arabic letter variants and accepts positive clues',
    () async {
      expect(normalizeDecoderWord('  كِتاب‌ي  '), 'کتابى'.replaceAll('ى', 'ی'));
      final cubit = DecoderCubit(repository: repository);
      await cubit.startGame(first, second);
      cubit.dismissShield();
      cubit.submitClue('  راهنما  ', '۳');
      expect(cubit.state.shieldTarget, DecoderPhase.guessing);
      expect(cubit.state.clue, 'راهنما');
      expect(cubit.state.clueCount, 3);
      expect(cubit.state.guessesLeft, 4);
      await cubit.close();
    },
  );

  test(
    'rejects zero, non-numeric and board-word clues after normalization',
    () async {
      final cubit = DecoderCubit(repository: repository);
      await cubit.startGame(first, second);
      cubit.dismissShield();
      for (final number in ['0', 'abc']) {
        cubit.submitClue('راهنما', number);
        expect(cubit.state.phase, DecoderPhase.guide);
        expect(cubit.state.error, isNotNull);
      }
      // Use a guaranteed card so normalization is compared with a board word.
      final boardWord = cubit.state.cards.first.word;
      cubit.submitClue(boardWord, '2');
      expect(cubit.state.phase, DecoderPhase.guide);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    },
  );

  test('neutral guesses pass through reveal and switch teams', () async {
    final cubit = DecoderCubit(repository: repository);
    await cubit.startGame(first, second);
    cubit.dismissShield();
    cubit.submitClue('راهنما', '۲');
    cubit.dismissShield();
    final index = cubit.state.cards.indexWhere(
      (card) => card.role == DecoderRole.neutral,
    );
    final oldTeam = cubit.state.activeTeam;
    cubit.guess(index);
    expect(cubit.state.phase, DecoderPhase.reveal);
    expect(cubit.state.activeTeam, 1 - oldTeam);
    expect(cubit.state.cards[index].revealed, isTrue);
    cubit.continueTurn();
    expect(cubit.state.phase, DecoderPhase.shield);
    expect(cubit.state.shieldTarget, DecoderPhase.guide);
    await cubit.close();
  });

  test(
    'opponent guesses reveal the card before handing off the turn',
    () async {
      final game = await repository.newGame(first, second);
      final opponentRole = game.activeTeam == 0
          ? DecoderRole.team1
          : DecoderRole.team0;
      final index = game.cards.indexWhere((card) => card.role == opponentRole);
      await repository.save(
        _snapshot(
          game,
          phase: DecoderPhase.guessing,
          clue: 'راهنما',
          clueCount: 1,
          guessesLeft: 2,
        ),
      );
      final cubit = DecoderCubit(repository: repository);
      cubit.dismissShield();
      final oldTeam = cubit.state.activeTeam;
      cubit.guess(index);
      expect(cubit.state.phase, DecoderPhase.reveal);
      expect(cubit.state.cards[index].revealed, isTrue);
      expect(cubit.state.activeTeam, 1 - oldTeam);
      await cubit.close();
    },
  );

  test(
    'hazard immediately awards the opposing team and records the result once',
    () async {
      final game = await repository.newGame(first, second);
      final guessing = _snapshot(
        game,
        phase: DecoderPhase.guessing,
        clue: 'راهنما',
        clueCount: 1,
        guessesLeft: 2,
      );
      await repository.save(guessing);
      final cubit = DecoderCubit(repository: repository);
      cubit.dismissShield();
      final hazard = cubit.state.cards.indexWhere(
        (card) => card.role == DecoderRole.hazard,
      );
      cubit.guess(hazard);
      cubit.guess(hazard);
      await cubit.close();

      expect(cubit.state.phase, DecoderPhase.result);
      expect(cubit.state.winner, 1 - game.activeTeam);
      expect(storage.getGameHistory(), hasLength(1));
      expect(
        storage.getGameHistory().single['winnerName'],
        game.teams[1 - game.activeTeam].name,
      );
    },
  );

  test(
    'a duplicate guess cannot reveal or consume the same card twice',
    () async {
      final game = await repository.newGame(first, second);
      final activeRole = game.activeTeam == 0
          ? DecoderRole.team0
          : DecoderRole.team1;
      final ownIndex = game.cards.indexWhere((card) => card.role == activeRole);
      await repository.save(
        _snapshot(
          game,
          phase: DecoderPhase.guessing,
          clue: 'راهنما',
          clueCount: 2,
          guessesLeft: 3,
        ),
      );
      final cubit = DecoderCubit(repository: repository);
      cubit.dismissShield();
      cubit.guess(ownIndex);
      final guessesAfterFirstTap = cubit.state.guessesLeft;
      final cardsAfterFirstTap = cubit.state.cards;
      cubit.guess(ownIndex);
      expect(cubit.state.guessesLeft, guessesAfterFirstTap);
      expect(cubit.state.cards, cardsAfterFirstTap);
      await cubit.close();
    },
  );

  test('completing the other team’s final word wins for that team', () async {
    final game = await repository.newGame(first, second);
    final otherRole = game.activeTeam == 0
        ? DecoderRole.team1
        : DecoderRole.team0;
    final otherIndices = [
      for (var i = 0; i < game.cards.length; i++)
        if (game.cards[i].role == otherRole) i,
    ];
    final completed = game.cards.asMap().entries.map((entry) {
      final shouldReveal = otherIndices
          .take(otherIndices.length - 1)
          .contains(entry.key);
      return shouldReveal ? entry.value.reveal() : entry.value;
    }).toList();
    final nearWin = game.copyWith(
      phase: DecoderPhase.guessing,
      cards: completed,
      clue: 'راهنما',
      clueCount: 1,
      guessesLeft: 2,
    );
    await repository.save(nearWin);
    final cubit = DecoderCubit(repository: repository);
    cubit.dismissShield();
    cubit.guess(otherIndices.last);
    expect(cubit.state.phase, DecoderPhase.result);
    expect(cubit.state.winner, otherRole == DecoderRole.team0 ? 0 : 1);
    await cubit.close();
  });

  test('invalid persisted snapshots are ignored', () async {
    await storage.saveActiveDecoder({'version': 1, 'cards': 'not a card list'});
    expect(repository.restore(), isNull);
    final cubit = DecoderCubit(repository: repository);
    expect(cubit.state.phase, DecoderPhase.setup);
    await cubit.close();
  });

  test('persisted games resume behind a shield at their prior phase', () async {
    final game = await repository.newGame(first, second);
    await repository.save(game.copyWith(phase: DecoderPhase.guide));
    final resumed = DecoderCubit(repository: repository);
    expect(resumed.state.phase, DecoderPhase.shield);
    expect(resumed.state.shieldTarget, DecoderPhase.guide);
    resumed.dismissShield();
    expect(resumed.state.phase, DecoderPhase.guide);
    await resumed.close();
  });

  test(
    'setup validation errors are owned and cleared by DecoderCubit',
    () async {
      final cubit = DecoderCubit(repository: repository);
      cubit.showRosterError('هر تیم دو عضو لازم دارد.');
      expect(cubit.state.rosterError, isNotNull);

      cubit.selectTeam(0, first.id);
      expect(cubit.state.rosterError, isNull);
      expect(cubit.state.selectedFirst, first.id);
      await cubit.close();
    },
  );
}

DecoderState _snapshot(
  DecoderState game, {
  required DecoderPhase phase,
  String clue = '',
  int clueCount = 0,
  int guessesLeft = 0,
}) => game.copyWith(
  phase: phase,
  clue: clue,
  clueCount: clueCount,
  guessesLeft: guessesLeft,
);
