import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/game_setup_config.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/haptics_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/features/charades/data/charades_repository.dart';
import 'package:flutter_application_1/features/charades/data/charades_word_model.dart';
import 'package:flutter_application_1/features/charades/presentation/cubit/charades_cubit.dart';
import 'package:flutter_application_1/features/drawing/data/drawing_repository.dart';
import 'package:flutter_application_1/features/drawing/data/drawing_word_model.dart';
import 'package:flutter_application_1/features/drawing/presentation/cubit/drawing_cubit.dart';

class _SingleCharadesWord implements CharadesRepository {
  _SingleCharadesWord(this.word);
  final CharadesWord word;

  @override
  bool get isLoaded => true;
  @override
  int get totalWords => 1;
  @override
  bool hasCategory(String category) => true;
  @override
  CharadesWord? findById(String id) => word.id == id ? word : null;
  @override
  Future<void> loadWords() async {}
  @override
  CharadesWord getNextWord({int? filterPoints, String category = 'all'}) =>
      word;
}

class _DrawingWords implements DrawingRepository {
  int _index = 0;

  @override
  bool get isLoaded => true;

  @override
  int get totalWords => 2;

  @override
  Future<void> loadWords() async {}

  @override
  DrawingWord getNextWord({int? difficulty}) => DrawingWord(
    id: 'draw_${_index++}',
    word: 'درخت',
    category: 'طبیعت',
    difficulty: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({
      'sound_enabled': false,
      'vibration_enabled': false,
    });
    final storage = StorageService(await SharedPreferences.getInstance());
    sl.registerSingleton<StorageService>(storage);
    sl.registerSingleton<AudioService>(AudioService(storage));
    sl.registerSingleton<HapticsService>(HapticsService(storage));
  });

  tearDown(() async => sl.reset());

  test(
    'charades category stays selected and cards carry their points',
    () async {
      expect(CharadesWord.pointsFor('آ'), 1);
      expect(CharadesWord.pointsFor('آب'), 2);
      expect(CharadesWord.pointsFor('اسب'), 2);
      expect(CharadesWord.pointsFor('کتاب'), 3);

      final setup = GameSetupConfig.fromArguments('charades', {
        'charadesCategory': 'حیوانات',
      });
      expect(setup.toArguments()['charadesCategory'], 'حیوانات');

      final repository = CharadesRepository();
      await repository.loadWords();
      expect(repository.hasCategory('حیوانات'), isTrue);
      for (var i = 0; i < 10; i++) {
        final word = repository.getNextWord(category: setup.charadesCategory);
        expect(word.category, 'حیوانات');
        expect(CharadesWord.isValid(word.word), isTrue);
        expect(word.points, inInclusiveRange(1, 3));
      }
    },
  );

  test(
    'bundled multiword charades entries are available in their category',
    () async {
      sl.registerSingleton<ContentService>(
        ContentService(sl<StorageService>()),
      );
      final repository = CharadesRepository();
      await repository.loadWords();
      expect(repository.totalWords, greaterThanOrEqualTo(299));
      expect(repository.hasCategory('چالش‌های نمایشی'), isTrue);
      final word = repository.getNextWord(category: 'چالش‌های نمایشی');
      expect(word.category, 'چالش‌های نمایشی');
      expect(word.word.contains(' '), isTrue);
      expect(word.points, inInclusiveRange(1, 3));
    },
  );

  test(
    'bundled card points are used for scoring and restored sessions',
    () async {
      sl.registerSingleton<ContentService>(
        ContentService(sl<StorageService>()),
      );
      final repository = CharadesRepository();
      await repository.loadWords();
      CharadesWord? target;
      for (var i = 0; i < repository.totalWords; i++) {
        final word = repository.getNextWord();
        if (word.id == 'charades_curated_300_free') {
          target = word;
          break;
        }
      }
      expect(target, isNotNull);
      expect(target!.word, 'گربه ترساندن');
      expect(target.category, 'کارها و حرکت‌ها');
      expect(target.points, 2);
      expect(target.difficulty, 2);
      final fixedRepository = _SingleCharadesWord(target);
      final first = CharadesCubit(
        repository: _SingleCharadesWord(
          CharadesWord(
            id: target.id,
            word: target.word,
            category: target.category,
            points: 3,
            difficulty: 1,
          ),
        ),
        isQuickMode: true,
      );
      first.startRound();
      await first.close();

      final resumed = CharadesCubit(
        repository: fixedRepository,
        isQuickMode: true,
        resumeSaved: true,
      );
      expect(resumed.hasRestoredSession, isTrue);
      expect(resumed.state.currentWord?.points, 2);
      expect(resumed.state.currentWord?.difficulty, 2);
      resumed.resume();
      resumed.onCorrect();
      expect(resumed.state.roundScore, 2);
      await resumed.close();
    },
  );

  test('personal charades cards remain playable and survive resume', () async {
    final storage = sl<StorageService>();
    await storage.saveCustomCards([
      {'id': 'custom_long', 'word': 'چتر بازی', 'category': 'شخصی'},
    ]);
    sl.registerSingleton<ContentService>(ContentService(storage));

    final repository = CharadesRepository();
    await repository.loadWords();
    expect(repository.hasCategory('کارت‌های من'), isTrue);
    final word = repository.getNextWord(category: 'کارت‌های من');
    expect(word.word, 'چتر بازی');
    expect(word.isCustom, isTrue);
    expect(word.points, 2);

    final first = CharadesCubit(
      repository: repository,
      isQuickMode: true,
      setup: const GameSetupConfig(charadesCategory: 'کارت‌های من'),
    );
    first.startRound();
    expect(first.state.currentWord?.word, 'چتر بازی');
    await first.close();

    final resumed = CharadesCubit(
      repository: repository,
      isQuickMode: true,
      resumeSaved: true,
    );
    expect(resumed.hasRestoredSession, isTrue);
    expect(resumed.state.currentWord?.word, 'چتر بازی');
    await resumed.close();
  });

  test('charades category survives leaving and resuming a round', () async {
    final repository = CharadesRepository();
    await repository.loadWords();
    final first = CharadesCubit(
      repository: repository,
      isQuickMode: true,
      setup: const GameSetupConfig(charadesCategory: 'حیوانات'),
    );
    first.startRound();
    expect(first.state.currentWord?.category, 'حیوانات');
    await first.close();

    final resumed = CharadesCubit(
      repository: repository,
      isQuickMode: true,
      resumeSaved: true,
    );
    expect(resumed.hasRestoredSession, isTrue);
    expect(resumed.selectedCategory, 'حیوانات');
    expect(resumed.state.currentWord?.category, 'حیوانات');
    await resumed.close();
  });

  test(
    'drawing timeout after a successful round earns no new points',
    () async {
      final cubit = DrawingCubit(
        repository: _DrawingWords(),
        isQuickMode: true,
        setup: const GameSetupConfig(roundSeconds: 1),
      );
      cubit.prepareWord();
      cubit.startDrawingOnCanvas();
      cubit.onCorrectGuess();
      expect(cubit.state.roundScore, 2);

      cubit.nextTurn();
      expect(cubit.state.roundScore, 0);
      cubit.startDrawingOnCanvas();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(cubit.state.isRoundOver, isTrue);
      expect(cubit.state.roundScore, 0);
      cubit.onCorrectGuess();
      expect(cubit.state.roundScore, 0);
      await cubit.close();
    },
  );
}
