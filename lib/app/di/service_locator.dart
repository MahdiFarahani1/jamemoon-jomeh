import '../../core/services/content_service.dart';
import '../../features/decoder/data/decoder_repository.dart';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/storage_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptics_service.dart';
import '../../core/services/purchase_service.dart';
import '../../features/taboo/data/taboo_repository.dart';
import '../../features/hot_potato/data/hot_potato_repository.dart';
import '../../features/charades/data/charades_repository.dart';
import '../../features/five_seconds/data/five_seconds_repository.dart';
import '../../features/drawing/data/drawing_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Safe SharedPreferences initialization with fallback
  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Could not initialize SharedPreferences: $e');
  }

  sl.registerLazySingleton<StorageService>(
    () => StorageService(sharedPreferences),
  );

  // Audio & Haptics
  sl.registerLazySingleton<AudioService>(
    () => AudioService(sl<StorageService>()),
  );
  sl.registerLazySingleton<HapticsService>(
    () => HapticsService(sl<StorageService>()),
  );

  // Keep the default app registration production-safe until a real Cafe Bazaar
  // billing adapter is configured. This exposes saved entitlements and the
  // catalog, but can never fabricate a successful checkout.
  sl.registerLazySingleton<PurchaseService>(
    () => LocalPurchaseService(sl<StorageService>()),
  );

  // Repositories for 5 Games
  sl.registerLazySingleton<TabooRepository>(() => TabooRepository());
  sl.registerLazySingleton<HotPotatoRepository>(() => HotPotatoRepository());
  sl.registerLazySingleton<CharadesRepository>(() => CharadesRepository());
  sl.registerLazySingleton<FiveSecondsRepository>(
    () => FiveSecondsRepository(),
  );

  // Content & Decoder
  sl.registerLazySingleton<ContentService>(
    () => ContentService(sl<StorageService>()),
  );
  sl.registerLazySingleton<DecoderRepository>(
    () => DecoderRepository(storageService: sl<StorageService>()),
  );

  sl.registerLazySingleton<DrawingRepository>(() => DrawingRepository());
}
