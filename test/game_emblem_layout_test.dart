import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/widgets/game_emblem.dart';

void main() {
  testWidgets('every game emblem keeps a square canvas in a narrow list', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const keys = [
      'taboo',
      'hot_potato',
      'charades',
      'five_seconds',
      'drawing',
      'decoder',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (final key in keys) GameEmblem(gameKey: key, size: 92),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < keys.length; i++) {
      final paint = find.descendant(
        of: find.byType(GameEmblem).at(i),
        matching: find.byType(CustomPaint),
      );
      expect(tester.getSize(paint), const Size(92, 92));
    }
    expect(tester.takeException(), isNull);
  });
}
