import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/game_setup_config.dart';
import 'package:flutter_application_1/core/models/game_stats.dart';
import 'package:flutter_application_1/core/services/content_history_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    sl.registerSingleton<StorageService>(
      StorageService(await SharedPreferences.getInstance()),
    );
  });

  tearDown(() async => sl.reset());

  test('legacy word mood arguments are ignored', () {
    final config = GameSetupConfig.fromArguments('taboo', {
      'difficulty': 'funny',
      'totalRounds': 1,
    });
    expect(config.totalRounds, 1);
    expect(config.toArguments(), isNot(contains('difficulty')));
  });

  test('result highlights survive session serialization', () {
    final stats = GameStatsTracker()
      ..add('سارا', GameStatMetric.correct, 4)
      ..add('علی', GameStatMetric.foul, 2)
      ..add('رضا', GameStatMetric.explosion);
    final restored = GameStatsTracker()..restore(stats.toJson());
    final highlights = restored.highlights();
    expect(
      highlights.map((item) => item.value),
      contains('سارا • 4 پاسخ درست'),
    );
    expect(
      highlights.map((item) => item.title),
      contains('بدشانس‌ترین بازیکن'),
    );
  });

  test('seen prompts stay out of the gathering deck until exhausted', () async {
    final storage = sl<StorageService>();
    await storage.markContentSeen('taboo', 'one');
    final deck = ContentHistoryService.freshDeck<String>('taboo', [
      'one',
      'two',
      'three',
    ], (item) => item);
    expect(deck, isNot(contains('one')));
    expect(deck.toSet(), {'two', 'three'});
    await storage.clearAll();
    expect(storage.getSeenContentIds('taboo'), isEmpty);
  });
}
