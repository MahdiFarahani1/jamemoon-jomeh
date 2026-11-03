class GameInfo {
  final String key;
  final String titleFa;
  final String subtitleFa;
  final String iconName;
  final int defaultRoundSeconds;

  const GameInfo({
    required this.key,
    required this.titleFa,
    required this.subtitleFa,
    required this.iconName,
    required this.defaultRoundSeconds,
  });

  static const List<GameInfo> tournamentGames = [
    GameInfo(
      key: 'taboo',
      titleFa: 'حرف نزن، بفهمون!',
      subtitleFa: 'بدون گفتن ۵ کلمه ممنوع توضیح بده',
      iconName: 'chat_bubble',
      defaultRoundSeconds: 60,
    ),
    GameInfo(
      key: 'hot_potato',
      titleFa: 'بمب دست کیه؟',
      subtitleFa: 'جواب بده، پاس بده قبل از انفجار!',
      iconName: 'timer',
      defaultRoundSeconds: 30,
    ),
    GameInfo(
      key: 'charades',
      titleFa: 'پانتومیم انفجاری',
      subtitleFa: 'فقط با ایما و اشاره به بازی دربیار',
      iconName: 'theater_comedy',
      defaultRoundSeconds: 60,
    ),
    GameInfo(
      key: 'five_seconds',
      titleFa: 'سه‌تا بگو!',
      subtitleFa: 'فقط ۵ ثانیه برای گفتن ۳ پاسخ',
      iconName: 'flash_on',
      defaultRoundSeconds: 5,
    ),
    GameInfo(
      key: 'drawing',
      titleFa: 'نقاشی افتضاح!',
      subtitleFa: 'با انگشت بکش تا حدس بزنن',
      iconName: 'brush',
      defaultRoundSeconds: 60,
    ),
  ];

  static const decoder = GameInfo(
    key: 'decoder',
    titleFa: 'رمزگشا',
    subtitleFa: 'یک سرنخ، چند کشف؛ رقابت دو تیم',
    iconName: 'key',
    defaultRoundSeconds: 0,
  );
  static const List<GameInfo> allGames = [...tournamentGames, decoder];
}
