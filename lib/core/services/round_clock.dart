import 'dart:async';

import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/team_model.dart';
import 'package:flutter_application_1/core/models/game_result.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';

/// A pausable monotonic countdown. Timer callbacks only refresh the display;
/// elapsed time comes from [Stopwatch], so delayed callbacks do not add time.
class RoundClock {
  RoundClock({required this.onChanged, required this.onFinished});

  final void Function(Duration remaining) onChanged;
  final void Function() onFinished;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _finished = false;

  Duration get remaining {
    final value = _remaining - _stopwatch.elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  bool get isRunning => _stopwatch.isRunning;

  /// Restore an interrupted round in a paused state.
  void restore(Duration remaining) {
    pause();
    _remaining = remaining;
    _finished = false;
  }

  void start(Duration duration) {
    pause();
    _remaining = duration;
    _finished = false;
    resume();
  }

  void resume() {
    if (_finished || isRunning || _remaining <= Duration.zero) return;
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    _tick();
  }

  void _tick() {
    if (!isRunning) return;
    final left = remaining;
    onChanged(left);
    if (left == Duration.zero && !_finished) {
      pause();
      _finished = true;
      onFinished();
    }
  }

  void pause() {
    if (isRunning) {
      _remaining = remaining;
      _stopwatch
        ..stop()
        ..reset();
    }
    _ticker?.cancel();
    _ticker = null;
  }

  void dispose() => pause();
}

/// Common versioned session bookkeeping for the five local games.
class GameSessionStore {
  GameSessionStore(this.gameKey)
    : sessionId = '${gameKey}_${DateTime.now().microsecondsSinceEpoch}';
  final String gameKey;
  String sessionId;
  StorageService? get _storage =>
      sl.isRegistered<StorageService>() ? sl<StorageService>() : null;

  Map<String, dynamic>? read() => _storage?.getGameSession(gameKey);

  void save(Map<String, dynamic> data) {
    _storage?.saveGameSession(gameKey, {
      'version': 1,
      'sessionId': sessionId,
      ...data,
    });
  }

  void clear() => _storage?.saveGameSession(gameKey, null);

  void complete(TurnManager? manager, {Map<String, int> baseline = const {}}) {
    if (manager == null) return;
    final result = GameResult.fromManager(manager, baseline: baseline);
    _storage?.recordGameResult(
      sessionId: sessionId,
      gameKey: gameKey,
      scores: {
        for (final team in result?.standings ?? <Team>[]) team.name: team.score,
      },
      winnerName: result?.winnerName,
    );
  }

  Map<String, dynamic>? encodeManager(TurnManager? manager) => manager == null
      ? null
      : {
          'teams': manager.teams.map((team) => team.toJson()).toList(),
          'index': manager.currentTeamIndex,
          'round': manager.currentRound,
          'totalRounds': manager.totalRounds,
        };

  TurnManager? decodeManager(Object? value, List<Team>? currentTeams) {
    if (value == null) return null;
    final map = Map<String, dynamic>.from(value as Map);
    final teams = (map['teams'] as List)
        .map((e) => Team.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final index = map['index'] as int;
    final round = map['round'] as int;
    final total = map['totalRounds'] as int;
    if (teams.isEmpty ||
        index < 0 ||
        index >= teams.length ||
        round < 1 ||
        total < 1 ||
        round > total + 1 ||
        currentTeams == null ||
        teams.length != currentTeams.length ||
        !List.generate(
          teams.length,
          (i) => teams[i].id == currentTeams[i].id,
        ).every((x) => x)) {
      throw const FormatException('Invalid saved team session');
    }
    return TurnManager(
      teams: teams,
      currentTeamIndex: index,
      currentRound: round,
      totalRounds: total,
    );
  }
}
