import 'player_model.dart';
import 'team_model.dart';

enum GameParticipationMode { teams, players }

/// Only games whose round clock is part of their rules expose a duration.
class GameSetupConfig {
  const GameSetupConfig({
    this.roundSeconds,
    this.totalRounds = 3,
    this.participationMode = GameParticipationMode.teams,
  });

  static const allowedSeconds = [30, 45, 60, 90];
  static const allowedRounds = [1, 3, 5, 7];

  final int? roundSeconds;
  final int totalRounds;
  final GameParticipationMode participationMode;

  static bool hasRoundDuration(String key) =>
      key == 'taboo' || key == 'charades' || key == 'drawing';

  static bool hasRounds(String key) => key != 'decoder';

  static bool supportsPlayerMode(String key) =>
      key == 'hot_potato' || key == 'five_seconds';
  static int minimumMembers(String key) =>
      key == 'taboo' ||
          key == 'charades' ||
          key == 'drawing' ||
          key == 'decoder'
      ? 2
      : 0;

  factory GameSetupConfig.initial(String key) =>
      GameSetupConfig(roundSeconds: hasRoundDuration(key) ? 60 : null);

  factory GameSetupConfig.fromArguments(String key, Map<String, dynamic> args) {
    final seconds = args['roundSeconds'];
    final rounds = args['totalRounds'];
    final mode = args['participationMode'] == GameParticipationMode.players.name
        ? GameParticipationMode.players
        : GameParticipationMode.teams;
    return GameSetupConfig(
      roundSeconds:
          hasRoundDuration(key) &&
              seconds is int &&
              allowedSeconds.contains(seconds)
          ? seconds
          : hasRoundDuration(key)
          ? 60
          : null,
      totalRounds: rounds is int && allowedRounds.contains(rounds) ? rounds : 3,
      participationMode: supportsPlayerMode(key)
          ? mode
          : GameParticipationMode.teams,
    );
  }

  GameSetupConfig copyWith({
    int? roundSeconds,
    int? totalRounds,
    GameParticipationMode? participationMode,
  }) => GameSetupConfig(
    roundSeconds: roundSeconds ?? this.roundSeconds,
    totalRounds: totalRounds ?? this.totalRounds,
    participationMode: participationMode ?? this.participationMode,
  );

  Map<String, dynamic> toArguments() => {
    if (roundSeconds != null) 'roundSeconds': roundSeconds,
    'totalRounds': totalRounds,
    if (participationMode == GameParticipationMode.players)
      'participationMode': participationMode.name,
  };
}

/// Validation is shared by the preparation screen and game-specific setup.
class GameSetupRequirements {
  static String? validate(
    String gameKey,
    List<Team> teams,
    List<Player> players, {
    GameParticipationMode participationMode = GameParticipationMode.teams,
  }) {
    if (participationMode == GameParticipationMode.players) {
      final names = players
          .map((player) => player.name.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.length < 2) {
        return 'برای حالت بازیکنی دست‌کم دو بازیکن با نام لازم است.';
      }
      if (names.toSet().length != names.length) {
        return 'نام بازیکن‌ها باید متفاوت باشد.';
      }
      return null;
    }
    if (teams.length < 2) {
      return 'برای شروع دست‌کم دو تیم لازم است.';
    }
    final names = teams.map((team) => team.name.trim()).toList();
    if (names.any((name) => name.isEmpty)) {
      return 'نام همهٔ تیم‌ها را وارد کنید.';
    }
    if (names.toSet().length != names.length) {
      return 'نام تیم‌ها باید متفاوت باشد.';
    }
    final minimum = GameSetupConfig.minimumMembers(gameKey);
    for (final team in teams) {
      final members = players
          .where((player) => player.teamId == team.id)
          .toList();
      if (members.length < minimum) {
        return 'تیم «${team.name}» به دست‌کم $minimum عضو نیاز دارد.';
      }
      if (members.any((player) => player.name.trim().isEmpty)) {
        return 'نام اعضای تیم «${team.name}» را کامل کنید.';
      }
    }
    return null;
  }
}
