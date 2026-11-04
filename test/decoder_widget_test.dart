import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/models/team_model.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/features/decoder/data/decoder_repository.dart';
import 'package:flutter_application_1/features/decoder/presentation/cubit/decoder_state.dart';
import 'package:flutter_application_1/features/decoder/presentation/pages/decoder_game_page.dart';

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
  final sl = GetIt.instance;
  late StorageService storage;
  late DecoderRepository repository;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
    repository = DecoderRepository(
      storageService: storage,
      random: Random(23),
      bundle: _WordBundle(),
    );
    sl.registerSingleton<DecoderRepository>(repository);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> saveGuideGame(WidgetTester tester) async {
    await tester.runAsync(() async {
      final teams = [
        const Team(id: 'first', name: 'تیم اول', colorValue: 1),
        const Team(id: 'second', name: 'تیم دوم', colorValue: 2),
      ];
      final game = await repository.newGame(teams[0], teams[1]);
      await repository.save(game.copyWith(phase: DecoderPhase.guide));
    });
  }

  Widget app() => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DecoderGamePage(resumeSaved: true),
              ),
            ),
            child: const Text('Open decoder'),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'the guide cannot see secret roles until choosing to reveal the map',
    (tester) async {
      await saveGuideGame(tester);
      await tester.pumpWidget(app());
      await tester.tap(find.text('Open decoder'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.lock_open_rounded));
      await tester.pumpAndSettle();
      expect(find.text(_words.first), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(find.text(_words.first), findsOneWidget);
      expect(find.text('تیم اول'), findsAtLeastNWidgets(1));

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(find.text(_words.first), findsNothing);
    },
  );

  testWidgets('system and app bar back confirm exit and preserve the game', (
    tester,
  ) async {
    await saveGuideGame(tester);
    final original = repository.restore()!;
    final originalCards = original.cards.map((card) => card.word).toList();
    await tester.pumpWidget(app());
    await tester.tap(find.text('Open decoder'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.lock_open_rounded));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('خروج از رمزگشا'), findsOneWidget);
    expect(
      find.text(
        'می‌خواهید از بازی خارج شوید؟ بازی ذخیره می‌شود و می‌توانید بعداً ادامه دهید.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('ادامه بازی'));
    await tester.pumpAndSettle();
    expect(find.text('رمزگشا'), findsOneWidget);
    expect(find.text('خروج از رمزگشا'), findsNothing);
    expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('خروج از رمزگشا'), findsOneWidget);
    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();
    expect(find.text('Open decoder'), findsOneWidget);
    final restored = repository.restore()!;
    expect(restored.cards.map((card) => card.word).toList(), originalCards);
    expect(restored.phase, DecoderPhase.shield);
    expect(restored.shieldTarget, DecoderPhase.guide);

    await tester.tap(find.text('Open decoder'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock_open_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();
    expect(find.text(originalCards.first), findsOneWidget);
  });

  testWidgets(
    'lifecycle, covering route, and back navigation leave the game shielded',
    (tester) async {
      await saveGuideGame(tester);
      await tester.pumpWidget(app());
      await tester.tap(find.text('Open decoder'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_open_rounded));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Covered route')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(storage.getActiveDecoder()?['phase'], DecoderPhase.shield.name);
      final restored = repository.restore();
      expect(restored?.phase, DecoderPhase.shield);
      expect(restored?.shieldTarget, DecoderPhase.guide);
    },
  );
}
