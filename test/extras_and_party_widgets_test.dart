import 'dart:math';
import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_dialog.dart';
import 'package:flutter_application_1/features/extras/cubit/extras_cubit.dart';
import 'package:flutter_application_1/features/extras/lucky_wheel/pages/lucky_wheel_page.dart';
import 'package:flutter_application_1/features/extras/random_picker/pages/random_picker_page.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
  });

  group('Wheel', () {
    testWidgets('selected segment remains under the top pointer across spins', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: LuckyWheelPage(),
          ),
        ),
      );

      final cubit = tester.element(find.byType(PartyButton)).read<WheelCubit>();
      final segmentAngle = 2 * pi / LuckyWheelPage.segments.length;
      for (var spin = 0; spin < 8; spin++) {
        await cubit.spin(LuckyWheelPage.segments.length, reducedMotion: true);
        await tester.pump();

        final selected = cubit.state.selected!;
        final pointerAngle = (-pi / 2 - cubit.state.rotation) % (2 * pi);
        final segmentAtPointer =
            (((pointerAngle + pi / 2) % (2 * pi)) / segmentAngle).floor() %
            LuckyWheelPage.segments.length;

        expect(cubit.state.busy, isFalse);
        expect(segmentAtPointer, selected);
        expect(find.text(LuckyWheelPage.segments[selected]), findsOneWidget);
      }
    });
  });

  group('Random picker', () {
    test(
      'empty input is ignored and a running pick cannot be restarted',
      () async {
        final cubit = PickerCubit();
        await cubit.pick(const []);
        expect(cubit.state.name, isNull);
        expect(cubit.state.busy, isFalse);

        final pendingPick = cubit.pick(const ['Ada', 'Grace']);
        expect(cubit.state.busy, isTrue);
        final nameDuringPick = cubit.state.name;
        await cubit.pick(const ['different']);
        expect(cubit.state.name, nameDuringPick);
        expect(cubit.state.busy, isTrue);

        await pendingPick;
        expect(cubit.state.busy, isFalse);
        expect(['Ada', 'Grace'], contains(cubit.state.name));
        await cubit.close();
      },
    );

    testWidgets('empty roster offers team setup without a picker action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {'/teams': (_) => const Scaffold(body: Text('Team setup'))},
          home: BlocProvider(
            create: (_) => TeamsCubit(storage),
            child: const RandomPickerPage(),
          ),
        ),
      );

      expect(find.text('هنوز بازیکنی ندارید'), findsOneWidget);
      expect(find.text('افزودن بازیکن'), findsOneWidget);
      expect(find.text('قرعه بنداز!'), findsNothing);
    });
  });

  test(
    'legacy custom card fields survive adding and removing a new card',
    () async {
      final legacyCard = <String, dynamic>{
        'word': 'old prompt',
        'category': 'legacy',
        'customMetadata': {'source': 'v1', 'rating': 4},
      };
      await storage.saveCustomCards([legacyCard]);
      final cubit = CustomCardsCubit(storage);

      await cubit.add('  new prompt  ', '  new category  ');
      expect(cubit.state, hasLength(2));
      expect(cubit.state.first, legacyCard);
      expect(cubit.state.last['word'], 'new prompt');
      expect(cubit.state.last['category'], 'new category');

      await cubit.remove(1);
      expect(cubit.state, [legacyCard]);
      expect(storage.getCustomCards(), [legacyCard]);
      await cubit.close();
    },
  );

  testWidgets('PartyDialog confirmation closes only its dialog route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-underlying-route'),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        key: const Key('open-dialog'),
                        onPressed: () => PartyDialog.show(
                          context,
                          title: 'Confirm',
                          message: 'Continue?',
                          confirmLabel: 'Confirm action',
                        ),
                        child: const Text('Open dialog'),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Open route'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-underlying-route')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Confirm action'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-dialog')), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
  });

  testWidgets('PartyButton exposes button semantics and disables interaction', (
    tester,
  ) async {
    var presses = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartyButton(label: 'Unavailable', onPressed: null),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(InkWell));
    expect(node.hasFlag(SemanticsFlag.isEnabled), isFalse);

    await tester.tap(find.byType(PartyButton));
    expect(presses, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartyButton(label: 'Available', onPressed: () => presses++),
        ),
      ),
    );
    final enabledNode = tester.getSemantics(find.byType(InkWell));
    expect(enabledNode.label, 'Available');
    await tester.tap(find.byType(PartyButton));
    expect(presses, 1);
    semantics.dispose();
  });
}
