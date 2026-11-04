class GameHighlight {
  const GameHighlight({
    required this.emoji,
    required this.title,
    required this.value,
  });

  final String emoji;
  final String title;
  final String value;
}

enum GameStatMetric { correct, foul, skip, fail, explosion }

class GameStatsTracker {
  final Map<String, Map<GameStatMetric, int>> _values = {};

  void add(String name, GameStatMetric metric, [int amount = 1]) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || amount <= 0) return;
    final stats = _values.putIfAbsent(cleanName, () => {});
    stats[metric] = (stats[metric] ?? 0) + amount;
  }

  Map<String, dynamic> toJson() => {
    for (final entry in _values.entries)
      entry.key: {
        for (final stat in entry.value.entries) stat.key.name: stat.value,
      },
  };

  void restore(Object? raw) {
    if (raw is! Map) return;
    _values.clear();
    for (final entry in raw.entries) {
      if (entry.value is! Map) continue;
      final stats = <GameStatMetric, int>{};
      for (final stat in (entry.value as Map).entries) {
        final metric = GameStatMetric.values
            .where((value) => value.name == stat.key)
            .firstOrNull;
        if (metric != null && stat.value is int && (stat.value as int) >= 0) {
          stats[metric] = stat.value as int;
        }
      }
      if (stats.isNotEmpty) _values[entry.key.toString()] = stats;
    }
  }

  GameHighlight? _best(
    GameStatMetric metric, {
    required String emoji,
    required String title,
    required String suffix,
  }) {
    final ranked =
        _values.entries
            .map((entry) => MapEntry(entry.key, entry.value[metric] ?? 0))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isEmpty) return null;
    return GameHighlight(
      emoji: emoji,
      title: title,
      value: '${ranked.first.key} • ${ranked.first.value} $suffix',
    );
  }

  List<GameHighlight> highlights() => <GameHighlight?>[
    _best(
      GameStatMetric.correct,
      emoji: '⭐',
      title: 'بهترین بازیکن',
      suffix: 'پاسخ درست',
    ),
    _best(
      GameStatMetric.foul,
      emoji: '🚫',
      title: 'بیشترین تخلف',
      suffix: 'خطا',
    ),
    _best(
      GameStatMetric.skip,
      emoji: '⏭️',
      title: 'بیشترین ردکردن',
      suffix: 'کارت',
    ),
    _best(
      GameStatMetric.explosion,
      emoji: '💥',
      title: 'بدشانس‌ترین بازیکن',
      suffix: 'انفجار',
    ),
    _best(
      GameStatMetric.fail,
      emoji: '😅',
      title: 'سخت‌ترین شب',
      suffix: 'پاسخ ناموفق',
    ),
  ].whereType<GameHighlight>().take(4).toList(growable: false);
}
