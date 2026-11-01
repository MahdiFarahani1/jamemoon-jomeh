import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptics_service.dart';
import '../../core/services/purchase_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<StorageService>(() => StorageService(sharedPreferences));

  // Audio & Haptics
  sl.registerLazySingleton<AudioService>(() => AudioService(sl<StorageService>()));
  sl.registerLazySingleton<HapticsService>(() => HapticsService(sl<StorageService>()));

  // In-App Purchase Service
  sl.registerLazySingleton<PurchaseService>(() => MockPurchaseService(sl<StorageService>()));
}
