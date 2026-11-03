import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/app/theme/app_theme.dart';
import 'package:flutter_application_1/core/models/game_mode.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/core/widgets/game_prompt_card.dart';
import 'package:flutter_application_1/core/widgets/pass_phone_overlay.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/features/drawing/presentation/widgets/palette_toolbar.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<StorageService>(StorageService());
  });

  tearDown(() async => sl.reset());

  Widget app(
    Widget child, {
    double textScale = 1,
    Locale locale = const Locale('fa', 'IR'),
  }) => MaterialApp(
    theme: AppTheme.darkTheme,
    locale: locale,
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

  testWidgets('home stays usable at narrow sizes with large RTL text', (
    tester,
  ) async {
    for (final width in [320.0, 360.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(app(const HomePage(), textScale: 2));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width $width');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets(
      'home scroll reveals games and extras at text scale $textScale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 800);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(app(const HomePage(), textScale: textScale));
        for (final game in GameInfo.allGames) {
          final tile = find.bySemanticsLabel(
            RegExp('^${RegExp.escape(game.titleFa)}'),
          );
          await tester.scrollUntilVisible(
            tile,
            260,
            scrollable: find.byType(Scrollable).first,
          );
          expect(tile, findsOneWidget, reason: 'Missing ${game.key}');
        }
        for (final icon in [
          Icons.casino_outlined,
          Icons.shuffle_rounded,
          Icons.style_outlined,
        ]) {
          final extra = find.byIcon(icon);
          await tester.scrollUntilVisible(
            extra,
            260,
            scrollable: find.byType(Scrollable).first,
          );
          expect(extra, findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('resume chip uses saved session without exposing a mode', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(
      () =>
          sl<StorageService>().saveGameSession('taboo', {'isQuickMode': true}),
    );
    RouteSettings? pushed;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomePage(),
        onGenerateRoute: (settings) {
          pushed = settings;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('route target')),
          );
        },
      ),
    );
    final resume = find.byType(ActionChip).first;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pump();
    await tester.tap(resume);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(pushed?.name, '/game/taboo');
    expect(pushed?.arguments, {'resume': true});
  });

  testWidgets('saved games wrap within a narrow home screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      await sl<StorageService>().saveGameSession('taboo', {'round': 1});
      await sl<StorageService>().saveGameSession('charades', {'round': 1});
    });

    await tester.pumpWidget(app(const HomePage()));
    final chips = find.byType(ActionChip);
    expect(chips, findsNWidgets(2));
    await tester.ensureVisible(chips.last);
    await tester.pump();
    for (var index = 0; index < 2; index++) {
      final rect = tester.getRect(chips.at(index));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Taboo opens its preparation route', (tester) async {
    RouteSettings? pushed;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomePage(),
        onGenerateRoute: (settings) {
          pushed = settings;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('route target')),
          );
        },
      ),
    );
    final tabooTile = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.onTap != null &&
          (widget.properties.label ?? '').contains(
            GameInfo.tournamentGames.first.titleFa,
          ),
    );
    await tester.ensureVisible(tabooTile);
    await tester.pumpAndSettle();
    await tester.tap(tabooTile);
    await tester.pumpAndSettle();
    expect(pushed?.name, '/prepare/taboo');
    expect(find.text('بازی سریع'), findsNothing);
  });

  testWidgets('game tiles expose actionable button semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(const HomePage()));
    await tester.scrollUntilVisible(
      find.bySemanticsLabel(
        RegExp('^${RegExp.escape(GameInfo.tournamentGames.first.titleFa)}'),
      ),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final node = tester.getSemantics(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.onTap != null &&
            (widget.properties.label ?? '').contains(
              GameInfo.tournamentGames.first.titleFa,
            ),
      ),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('PartyButton exposes enabled button semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    var presses = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: PartyButton(label: 'Ready', onPressed: () => presses++),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(PartyButton));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await tester.tap(find.byType(PartyButton));
    expect(presses, 1);
    semantics.dispose();
  });

  testWidgets(
    'GamePromptCard scrolls long Persian content at 240 square and 2x text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      const prompt =
          'Ø§ÛŒÙ† ÛŒÚ© Ù…ØªÙ† Ø¨Ø³ÛŒØ§Ø± Ø¨Ù„Ù†Ø¯ ÙØ§Ø±Ø³ÛŒ Ø§Ø³Øª Ú©Ù‡ Ø¨Ø§ÛŒØ¯ Ø¯Ø± Ú©Ø§Ø±Øª Ø¨Ø§Ø²ÛŒ Ø¨Ù‡â€ŒØ¯Ø±Ø³ØªÛŒ Ù†Ù…Ø§ÛŒØ´ Ø¯Ø§Ø¯Ù‡ Ø´ÙˆØ¯ Ùˆ Ø¨ØªÙˆØ§Ù† Ø¢Ù† Ø±Ø§ Ù¾ÛŒÙ…Ø§ÛŒØ´ Ú©Ø±Ø¯';
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: GamePromptCard(
                  gameKey: 'charades',
                  category:
                      'Ø¯Ø³ØªÙ‡â€ŒØ¨Ù†Ø¯ÛŒ Ø¨Ø³ÛŒØ§Ø± Ø·ÙˆÙ„Ø§Ù†ÛŒ ÙØ§Ø±Ø³ÛŒ',
                  prompt: prompt,
                  points: 100,
                  hint: 'Ø±Ø§Ù‡Ù†Ù…Ø§ÛŒ Ø·ÙˆÙ„Ø§Ù†ÛŒ ÙØ§Ø±Ø³ÛŒ Ø¨Ø±Ø§ÛŒ Ø¨Ø±Ø±Ø³ÛŒ Ù¾ÛŒÙ…Ø§ÛŒØ´ Ú©Ø§Ø±Øª',
                ),
              ),
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pump();
      expect(find.text(prompt), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('palette remains usable at 280px and every control fires', (
    tester,
  ) async {
    Color? selectedColor;
    double? selectedWidth;
    var eraser = 0, undo = 0, clear = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: PaletteToolbar(
                activeColor: Colors.white,
                strokeWidth: 3,
                isEraser: false,
                onColorChanged: (color) => selectedColor = color,
                onStrokeWidthChanged: (width) => selectedWidth = width,
                onToggleEraser: () => eraser++,
                onUndo: () => undo++,
                onClear: () => clear++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(InkWell).first);
    expect(selectedColor, PaletteToolbar.palette.first);
    final controls = find.byType(IconButton);
    await tester.tap(controls.at(0));
    await tester.tap(controls.at(1));
    await tester.tap(controls.at(2));
    await tester.tap(controls.at(3));
    expect(eraser, 1);
    expect(selectedWidth, 7);
    expect(undo, 1);
    expect(clear, 1);
  });

  testWidgets(
    'pass phone count-in waits three seconds and ignores duplicate taps',
    (tester) async {
      var ready = 0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      await tester.pumpWidget(
        app(
          PassPhoneOverlay(
            teamName: 'Team',
            gameTitle: 'Taboo',
            onReady: () => ready++,
          ),
        ),
      );
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.tap(find.byType(PartyButton));
      await tester.pump();
      await tester.tap(find.byType(PartyButton));
      await tester.pump(const Duration(seconds: 2));
      expect(ready, 0);
      await tester.pump(const Duration(milliseconds: 999));
      expect(ready, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(ready, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(ready, 1);
    },
  );

  testWidgets('pass phone cancel resets and allows a fresh count-in', (
    tester,
  ) async {
    var ready = 0;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    await tester.pumpWidget(
      app(
        PassPhoneOverlay(
          teamName: 'Team',
          gameTitle: 'Taboo',
          onReady: () => ready++,
        ),
      ),
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.tap(find.byType(PartyButton));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.byType(PartyButton), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(ready, 0);
    await tester.tap(find.byType(PartyButton));
    await tester.pump(const Duration(seconds: 3));
    expect(ready, 1);
  });

  testWidgets(
    'pass phone interruption and disposal suppress pending callback',
    (tester) async {
      var ready = 0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      await tester.pumpWidget(
        app(
          PassPhoneOverlay(
            teamName: 'Team',
            gameTitle: 'Taboo',
            onReady: () => ready++,
          ),
        ),
      );
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.tap(find.byType(PartyButton));
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(ready, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(find.byType(PartyButton));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
      expect(ready, 0);
    },
  );
}
