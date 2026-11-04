import 'dart:async';

import '../../app/di/service_locator.dart';
import 'storage_service.dart';

/// Keeps prompts fresh across multiple games in the same gathering.
class ContentHistoryService {
  static List<T> freshDeck<T>(
    String gameKey,
    List<T> all,
    String Function(T item) idOf,
  ) {
    final storage = sl.isRegistered<StorageService>()
        ? sl<StorageService>()
        : null;
    final seen = storage?.getSeenContentIds(gameKey).toSet() ?? <String>{};
    var available = all.where((item) => !seen.contains(idOf(item))).toList();
    if (available.isEmpty) {
      available = List<T>.of(all);
      if (storage != null) unawaited(storage.clearSeenContent(gameKey));
    }
    available.shuffle();
    return available;
  }

  static void markSeen(String gameKey, String id) {
    if (sl.isRegistered<StorageService>()) {
      unawaited(sl<StorageService>().markContentSeen(gameKey, id));
    }
  }

  static void reset(String gameKey) {
    if (sl.isRegistered<StorageService>()) {
      unawaited(sl<StorageService>().clearSeenContent(gameKey));
    }
  }
}
