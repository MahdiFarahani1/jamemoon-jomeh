import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/app/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/game_scene.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/features/taboo/data/taboo_repository.dart';
import 'package:flutter_application_1/features/taboo/presentation/pages/taboo_game_page.dart';
import 'package:flutter_application_1/features/taboo/presentation/widgets/taboo_card_view.dart';
import 'package:flutter_application_1/features/extras/party_challenges/challenge_deck.dart';
import 'package:flutter_application_1/features/extras/party_challenges/party_challenges_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget child, {double textScale = 1}) => MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('fa', 'IR'),
    supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
    home: child,
  );

  test('deck contains 24 unique valid cards across all three kinds', () {
    final ids = challenges.map((card) => card.id).toSet();
    final titles = challenges.map((card) => card.title.trim()).toSet();
    expect(challenges, hasLength(24));
    expect(ids, hasLength(24));
    expect(titles, hasLength(24));
    expect(ChallengeKind.values, hasLength(3));
    for (final kind in ChallengeKind.values) {
      final cards = challenges.where((card) => card.kind == kind);
      expect(cards, hasLength(8));
      for (final card in cards) {
        expect(card.id, isNotEmpty);
        expect(card.title, isNotEmpty);
        expect(card.instruction, isNotEmpty);
        expect(card.seconds, greaterThan(0));
      }
    }
  });

  test('unfiltered and filtered draws exhaust each pool without repeats', () {
    final deck = ChallengeDeck(random: Random(11));
    final all = List.generate(challenges.length, (_) => deck.draw());
    expect(all.map((card) => card.id).toSet(), hasLength(challenges.length));
    expect(deck.reshuffled, isFalse);
    final next = deck.draw();
    expect(next.id, isNot(all.last.id));
    expect(deck.reshuffled, isTrue);

    for (final kind in ChallengeKind.values) {
      final filteredDeck = ChallengeDeck(random: Random(7));
      final draws = List.generate(
        challenges.where((card) => card.kind == kind).length,
        (_) => filteredDeck.draw(kind),
      );
      expect(draws.every((card) => card.kind == kind), isTrue);
      expect(draws.map((card) => card.id).toSet(), hasLength(8));
      expect(filteredDeck.reshuffled, isFalse);
      expect(filteredDeck.draw(kind).id, isNot(draws.last.id));
      expect(filteredDeck.reshuffled, isTrue);
    }
  });

  test(
    'switching a filter retains seen cards and avoids an immediate repeat',
    () {
      final deck = ChallengeDeck(random: Random(3));
      final acting = List.generate(4, (_) => deck.draw(ChallengeKind.acting));
      final imagination = deck.draw(ChallengeKind.imagination);
      expect(imagination.kind, ChallengeKind.imagination);
      final switchedBack = deck.draw(ChallengeKind.acting);
      expect(switchedBack.kind, ChallengeKind.acting);
      expect(switchedBack.id, isNot(acting.last.id));
      expect(switchedBack.id, isNot(anyOf(acting.map((card) => card.id))));
    },
  );

  testWidgets('challenge clock starts idle, pauses, and requires resume', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app(const PartyChallengesPage()));
    final startPause = find.byType(OutlinedButton);
    expect(startPause, findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    await tester.ensureVisible(startPause);
    await tester.tap(startPause);
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.tap(startPause);
    await tester.pump();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sub-second pause and resume preserves real elapsed time', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app(const PartyChallengesPage()));
    await tester.ensureVisible(find.byType(OutlinedButton));
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('29'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('next card and filter change stop the active clock', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app(const PartyChallengesPage()));
    await tester.ensureVisible(find.byType(OutlinedButton));
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.ensureVisible(find.byType(PartyButton).last);
    await tester.tap(find.byType(PartyButton).last);
    await tester.pump();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.ensureVisible(find.byType(ChoiceChip).at(1));
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pump();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('filtered challenge footer reports only that kind’s cards', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app(const PartyChallengesPage()));
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pump();
    final footer = find.byWidgetPredicate(
      (widget) =>
          widget is Text && (widget.data ?? '').contains('8 کارت در این بخش'),
    );
    await tester.scrollUntilVisible(
      footer,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(footer, findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('quick Taboo waits for ready count-in before showing a prompt', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sound_enabled': false,
      'vibration_enabled': false,
    });
    await sl.reset();
    await initDependencies();
    addTearDown(() async => sl.reset());
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.runAsync(() async {
      await sl<TabooRepository>().loadCards();
    });
    await tester.pumpWidget(app(const TabooGamePage(isQuickMode: true)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    expect(find.byType(TabooCardView), findsNothing);
    await tester.tap(find.text('قرعه شروع'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('گوشی دستمه، شروع شمارش'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TabooCardView), findsOneWidget);
    expect(find.text('قرعه شروع'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('completion counts once and next card resets completion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app(const PartyChallengesPage()));
    final done = find.byIcon(Icons.celebration_rounded);
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pump();
    expect(done, findsNothing);
    await tester.ensureVisible(find.byType(PartyButton).last);
    await tester.tap(find.byType(PartyButton).last);
    await tester.pump();
    expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [320.0, 640.0]) {
    testWidgets(
      'challenge controls remain reachable at ${width.toInt()}px RTL 2x',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(app(const PartyChallengesPage(), textScale: 2));
        expect(tester.takeException(), isNull);
        final scrollable = find.byType(Scrollable).first;
        var sawFilters = false;
        var sawTimer = false;
        var sawDone = false;
        var sawNext = false;
        for (var i = 0; i < 20; i++) {
          sawFilters |= find.byType(ChoiceChip).evaluate().isNotEmpty;
          sawTimer |= find.byType(OutlinedButton).evaluate().isNotEmpty;
          sawDone |= find
              .byIcon(Icons.celebration_rounded)
              .evaluate()
              .isNotEmpty;
          sawNext |= find.byType(PartyButton).evaluate().isNotEmpty;
          await tester.drag(scrollable, const Offset(0, -100));
          await tester.pump();
        }
        sawFilters |= find.byType(ChoiceChip).evaluate().isNotEmpty;
        sawTimer |= find.byType(OutlinedButton).evaluate().isNotEmpty;
        sawDone |= find.byIcon(Icons.celebration_rounded).evaluate().isNotEmpty;
        sawNext |= find.byType(PartyButton).evaluate().isNotEmpty;
        expect(sawFilters, isTrue);
        expect(sawTimer, isTrue);
        expect(sawDone, isTrue);
        expect(sawNext, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('disposing a running challenge cancels its clock', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app(const PartyChallengesPage()));
    await tester.ensureVisible(find.byType(OutlinedButton));
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 31));
    expect(tester.takeException(), isNull);
  });

  testWidgets('score burst queues positive and negative score changes', (
    tester,
  ) async {
    const child = Text('score');
    Widget scene(int score, Object round) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: ScoreBurst(score: score, roundKey: round, child: child),
      ),
    );
    await tester.pumpWidget(scene(10, 'round-1'));
    expect(find.textContaining('+'), findsNothing);
    await tester.pumpWidget(scene(15, 'round-1'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('+5'), findsOneWidget);
    final transform = tester.widget<Transform>(
      find
          .ancestor(
            of: find.textContaining('+5'),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.getTranslation().y, 0);
    await tester.pumpWidget(scene(15, 'round-1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('+5'), findsOneWidget);
    await tester.pumpWidget(scene(12, 'round-1'));
    expect(find.textContaining('+5'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('-3'), findsOneWidget);
    await tester.pumpWidget(scene(12, 'round-2'));
    expect(find.textContaining('+'), findsNothing);
    await tester.pumpWidget(scene(20, 'round-2'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('+'), findsNothing);
  });
}
