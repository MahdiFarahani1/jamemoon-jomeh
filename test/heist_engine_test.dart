import 'dart:math';

import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/features/heist/data/heist_catalog.dart';
import 'package:flutter_application_1/features/heist/domain/heist_models.dart';
import 'package:flutter_application_1/features/heist/presentation/cubit/heist_cubit.dart';
import 'package:flutter_application_1/features/heist/presentation/pages/heist_game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
  });

  tearDown(() async => sl.reset());

  test('catalog contains eight roles, five banks, and thirty crises', () {
    expect(HeistCatalog.roles, hasLength(8));
    expect(HeistCatalog.roles.map((role) => role.id).toSet(), hasLength(8));
    expect(HeistCatalog.banks, hasLength(5));
    expect(HeistCatalog.events, hasLength(30));
    expect(HeistCatalog.events.map((event) => event.id).toSet(), hasLength(30));
  });

  testWidgets('narrow setup keeps selector readable and opens the tutorial', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fa'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: HeistGamePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final selected = tester.widget<ChoiceChip>(find.byType(ChoiceChip).first);
    expect(selected.selected, isTrue);
    expect(selected.selectedColor, const Color(0xFFE6B85C));
    await tester.ensureVisible(find.text('آموزش بازی'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('آموزش بازی'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('آموزش سرقت بزرگ'), findsOneWidget);
    expect(find.text('داستان و هدف بازی'), findsOneWidget);
  });

  testWidgets('infiltration choices stay readable and selected on narrow UI', (
    tester,
  ) async {
    // Keep phone width narrow while giving the multi-phase flow enough height
    // to test selection styling without scroll animation timing noise.
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fa'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: HeistGamePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('تشکیل گروه و شروع پرونده'));
    await tester.tap(find.text('تشکیل گروه و شروع پرونده'));
    await tester.pump(const Duration(milliseconds: 400));

    for (var i = 1; i <= 4; i++) {
      final reveal = find.text('بازیکن $i، مشاهده نقش');
      await tester.ensureVisible(reveal);
      await tester.tap(reveal);
      await tester.pump(const Duration(milliseconds: 400));
      final hide = find.text('نقش را حفظ کردم؛ پنهانش کن');
      await tester.ensureVisible(hide);
      await tester.tap(hide);
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.textContaining('شرط عملیات:'), findsOneWidget);
    final technology = find.widgetWithText(ChoiceChip, 'حمله سایبری');
    await tester.ensureVisible(technology);
    await tester.tap(technology);
    await tester.pump(const Duration(milliseconds: 300));
    final selected = tester.widget<ChoiceChip>(technology);
    expect(selected.selected, isTrue);
    expect(selected.selectedColor, const Color(0xFF3279C8));
    expect(tester.takeException(), isNull);
  });

  test(
    'four through eight players all receive one unique secret role',
    () async {
      for (var count = 4; count <= 8; count++) {
        final cubit = HeistCubit(random: Random(count));
        cubit.setPlayerCount(count);
        for (var i = 0; i < count; i++) {
          cubit.renamePlayer(i, 'عضو ${i + 1}');
        }
        cubit.startGame();
        expect(cubit.state.players, hasLength(count));
        expect(
          cubit.state.players.map((p) => p.roleId).toSet(),
          hasLength(count),
        );
        for (var i = 0; i < count; i++) {
          expect(cubit.state.phase, HeistPhase.rolePass);
          cubit.revealRole();
          cubit.hideRole();
        }
        expect(cubit.state.phase, HeistPhase.planning);
        await cubit.close();
      }
    },
  );

  test('difficulty changes the score target and alarm tolerance', () async {
    final targetOffsets = <int>[];
    final limits = <int>[];
    for (final difficulty in HeistDifficulty.values) {
      final cubit = await _startedHeist(difficulty: difficulty);
      targetOffsets.add(cubit.operationTarget - cubit.currentBank.security);
      limits.add(cubit.alarmLimit);
      await cubit.close();
    }

    expect(targetOffsets, [2, 4, 6]);
    expect(limits, [10, 8, 6]);
  });

  test('EMP absorbs only the first failed crisis', () async {
    final cubit = await _startedHeist();
    cubit.choosePlan(HeistApproach.technology);
    cubit.chooseEquipment('emp');
    cubit.beginOperation();

    HeistApproach wrongResponse() => HeistApproach.values.firstWhere(
      (approach) => approach != cubit.currentEvent.bestApproach,
    );

    cubit.resolveEvent(wrongResponse());
    expect(cubit.state.alarm, 0);
    expect(cubit.state.report.last, contains('EMP'));

    cubit.resolveEvent(wrongResponse());
    expect(cubit.state.alarm, greaterThan(0));
    expect(cubit.state.report.last, contains('تصمیم اشتباه'));
    await cubit.close();
  });

  test('a complete session reaches every player in all three heists', () async {
    final cubit = HeistCubit(random: Random(42));
    cubit.setPlayerCount(4);
    for (var i = 0; i < 4; i++) {
      cubit.renamePlayer(i, 'بازیکن ${i + 1}');
    }
    cubit.startGame();
    for (var i = 0; i < 4; i++) {
      cubit.revealRole();
      cubit.hideRole();
    }

    final visitedBanks = <String>{};
    for (var heist = 0; heist < 3; heist++) {
      expect(cubit.state.phase, HeistPhase.planning);
      visitedBanks.add(cubit.state.bankId!);
      cubit.choosePlan(HeistApproach.technology);
      cubit.chooseEquipment('signal');
      cubit.beginOperation();
      while (cubit.state.phase == HeistPhase.operation) {
        cubit.resolveEvent(cubit.currentEvent.bestApproach);
      }
      for (var player = 0; player < 4; player++) {
        expect(cubit.state.secretIndex, player);
        cubit.openSecretChoice();
        cubit.chooseSecret(HeistSecretAction.cooperate);
      }
      expect(cubit.state.phase, HeistPhase.operationReveal);
      cubit.openAccusation();
      cubit.accuse(null);
      expect(cubit.state.proposalTotal, cubit.state.loot);
      expect(cubit.state.proposal.every((share) => share >= 0), isTrue);
      cubit.submitProposal();
      for (var player = 0; player < 4; player++) {
        expect(cubit.state.voteIndex, player);
        cubit.openVote();
        cubit.castVote(true);
      }
      expect(cubit.state.phase, HeistPhase.heistSummary);
      expect(cubit.state.players.every((player) => player.cash >= 0), isTrue);
      cubit.continueAfterSummary();
    }
    expect(visitedBanks, hasLength(3));
    expect(cubit.state.phase, HeistPhase.finalResult);
    await cubit.close();
  });

  test('saved secret choice resumes behind the pass-phone shield', () async {
    final cubit = HeistCubit(random: Random(7));
    for (var i = 0; i < 4; i++) {
      cubit.renamePlayer(i, 'اسم ${i + 1}');
    }
    cubit.startGame();
    for (var i = 0; i < 4; i++) {
      cubit.revealRole();
      cubit.hideRole();
    }
    cubit.choosePlan(HeistApproach.stealth);
    cubit.chooseEquipment('drone');
    cubit.beginOperation();
    while (cubit.state.phase == HeistPhase.operation) {
      cubit.resolveEvent(cubit.currentEvent.bestApproach);
    }
    cubit.openSecretChoice();
    expect(cubit.state.phase, HeistPhase.secretChoice);
    final resumed = HeistCubit(random: Random(8), resume: true);
    expect(resumed.state.phase, HeistPhase.secretPass);
    expect(resumed.state.secretIndex, cubit.state.secretIndex);
    await resumed.close();
    await cubit.close();
  });

  test(
    'betrayal can be detected and two rejected offers force a settlement',
    () async {
      final cubit = HeistCubit(random: Random(99));
      cubit.setDifficulty(HeistDifficulty.legendary);
      for (var i = 0; i < 4; i++) {
        cubit.renamePlayer(i, 'مظنون ${i + 1}');
      }
      cubit.startGame();
      for (var i = 0; i < 4; i++) {
        cubit.revealRole();
        cubit.hideRole();
      }
      cubit.choosePlan(HeistApproach.force);
      cubit.chooseEquipment('thermal');
      cubit.beginOperation();
      while (cubit.state.phase == HeistPhase.operation) {
        cubit.resolveEvent(HeistApproach.social);
      }
      for (final action in const [
        HeistSecretAction.steal,
        HeistSecretAction.protect,
        HeistSecretAction.sabotage,
        HeistSecretAction.cooperate,
      ]) {
        cubit.openSecretChoice();
        cubit.chooseSecret(action);
      }
      expect(cubit.state.phase, HeistPhase.operationReveal);
      expect(
        cubit.state.players.take(3).any((player) => player.detected),
        isTrue,
      );
      cubit.openAccusation();
      cubit.accuse(0);
      expect(cubit.state.message, contains('درست'));
      final originalLoot = cubit.state.loot;

      cubit.submitProposal();
      for (var i = 0; i < 4; i++) {
        cubit.openVote();
        cubit.castVote(false);
      }
      expect(cubit.state.phase, HeistPhase.division);
      expect(cubit.state.loot, (originalLoot * .85).floor());
      cubit.submitProposal();
      for (var i = 0; i < 4; i++) {
        cubit.openVote();
        cubit.castVote(false);
      }
      expect(cubit.state.phase, HeistPhase.heistSummary);
      expect(cubit.state.proposalTotal, cubit.state.loot);
      expect(cubit.state.players.every((player) => player.cash >= 0), isTrue);
      await cubit.close();
    },
  );
}

Future<HeistCubit> _startedHeist({
  HeistDifficulty difficulty = HeistDifficulty.professional,
}) async {
  final cubit = HeistCubit(random: Random(314));
  cubit.setDifficulty(difficulty);
  for (var i = 0; i < 4; i++) {
    cubit.renamePlayer(i, 'آزمایش ${i + 1}');
  }
  cubit.startGame();
  for (var i = 0; i < 4; i++) {
    cubit.revealRole();
    cubit.hideRole();
  }
  expect(cubit.state.phase, HeistPhase.planning);
  return cubit;
}
