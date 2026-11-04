import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/widgets/game_visual_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testApp(Widget child) => MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(body: child),
    ),
  );

  testWidgets('each featured game atmosphere paints without layout errors', (
    tester,
  ) async {
    for (final gameKey in const [
      'hot_potato',
      'charades',
      'taboo',
      'drawing',
      'five_seconds',
    ]) {
      await tester.pumpWidget(
        testApp(
          GameAtmosphere(
            gameKey: gameKey,
            child: const Center(child: Text('game content')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('game content'), findsOneWidget, reason: gameKey);
      expect(tester.takeException(), isNull, reason: gameKey);
    }
  });

  testWidgets('bomb atmosphere keeps animating after its first cycle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameAtmosphere(
            gameKey: 'hot_potato',
            child: Center(child: Text('live bomb arena')),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));

    expect(find.text('live bomb arena'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'result celebration keeps content accessible with reduced motion',
    (tester) async {
      await tester.pumpWidget(
        testApp(
          const GameResultCelebration(
            gameKey: 'drawing',
            child: Center(child: Text('final result')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('final result'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
