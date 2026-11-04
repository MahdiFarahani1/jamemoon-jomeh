import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/models/turn_manager.dart';
import '../../../../core/models/game_result.dart';
import '../../../../core/models/game_setup_config.dart';
import '../../../../core/models/game_stats.dart';
import '../../../../core/models/participant_roster.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/round_clock.dart';
import '../../../teams/presentation/cubit/teams_cubit.dart';
import '../../data/hot_potato_repository.dart';
import '../../data/hot_potato_topic_model.dart';
import 'hot_potato_state.dart';

class BombPulseSchedule {
  int _nextPulseAtMs = 0;

  void reset() => _nextPulseAtMs = 0;

  bool shouldPulse(int elapsedMs, double tension) {
    if (elapsedMs < _nextPulseAtMs) return false;
    final urgency = tension * tension;
    final interval = (800 - urgency * 550).round().clamp(250, 800);
    _nextPulseAtMs = elapsedMs + interval;
    return true;
  }
}

class HotPotatoCubit extends Cubit<HotPotatoState> {
  GameResult? get result => GameResult.fromManager(
    _turnManager,
    baseline: _startingScores,
    highlights: _stats.highlights(),
  );
  final GameStatsTracker _stats = GameStatsTracker();
  Map<String, int> _startingScores = {};
  final GameSessionStore _session = GameSessionStore('hot_potato');
  bool _sessionReady = false;
  bool hasRestoredSession = false;
  final HotPotatoRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  final Random _random = Random();
  late final RoundClock _clock = RoundClock(
    onChanged: _onClockChanged,
    onFinished: _onFuseFinished,
  );
  TurnManager? _turnManager;
  final TeamsCubit? _teamsCubit;
  final GameSetupConfig? _setup;
  final bool _usesPlayers;
  int _completedRounds = 0;
  final _pulseSchedule = BombPulseSchedule();
  int get _participantCount => _turnManager?.teams.length ?? 4;

  HotPotatoCubit({
    required HotPotatoRepository repository,
    GameSetupConfig? setup,
    bool isQuickMode = false,
    bool resumeSaved = false,
    TeamsCubit? teamsCubit,
  }) : _repository = repository,
       _teamsCubit = teamsCubit,
       _setup = setup,
       _usesPlayers = setup?.participationMode == GameParticipationMode.players,
       super(HotPotatoState(isQuickMode: isQuickMode)) {
    if (!isQuickMode && teamsCubit != null) {
      final participants = _usesPlayers
          ? playerTeams(teamsCubit.state.players)
          : teamsCubit.state.teams;
      _startingScores = {for (final team in participants) team.id: team.score};
      _turnManager = TurnManager.randomStart(
        teams: participants,
        totalRounds: setup?.totalRounds ?? 3,
      );
      emit(
        state.copyWith(
          holdingTeamOrPlayer: _turnManager!.currentTeam.name,
          currentRound: _turnManager!.currentRound,
          totalRounds: _turnManager!.totalRounds,
        ),
      );
    }
    _initializeSession(resumeSaved);
  }

  void _initializeSession(bool resumeSaved) {
    final data = resumeSaved ? _session.read() : null;
    if (data != null) {
      try {
        if (data['version'] != 1 || data['isQuickMode'] != state.isQuickMode) {
          throw const FormatException();
        }
        final manager = _session.decodeManager(
          data['manager'],
          _teamsCubit == null
              ? null
              : _usesPlayers
              ? playerTeams(_teamsCubit.state.players)
              : _teamsCubit.state.teams,
        );
        if (!state.isQuickMode && manager == null) {
          throw const FormatException();
        }
        final rawItem = data['item'];
        final item = rawItem == null
            ? null
            : HotPotatoTopic.fromJson(
                Map<String, dynamic>.from(rawItem as Map),
              );
        final remainingMs = data['remainingMs'] as int;
        if (remainingMs < 0) {
          throw const FormatException();
        }
        _startingScores =
            (data['startingScores'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value as int),
            ) ??
            _startingScores;
        _turnManager = manager;
        _session.sessionId = data['sessionId'] as String;
        _stats.restore(data['stats']);
        _completedRounds = (data['completedRounds'] as int?) ?? 0;
        final isExploded = data['isExploded'] as bool;
        _clock.restore(Duration(milliseconds: remainingMs));
        super.emit(
          state.copyWith(
            currentTopic: item,
            elapsedSeconds: data['elapsedSeconds'] as int,
            hiddenBombDuration: data['hiddenBombDuration'] as int,
            isExploded: isExploded,
            isTicking: false,
            isFuseExpired: data['isFuseExpired'] == true,
            isReadyPhase: data['isReadyPhase'] as bool,
            turnPassCount: data['turnPassCount'] as int,
            holdingTeamOrPlayer: data['holdingTeamOrPlayer'] as String,
            loserName: data['loserName'] as String?,
            currentRound: data['currentRound'] as int,
            totalRounds: data['totalRounds'] as int,
            isGameOver: data['isGameOver'] as bool,
          ),
        );
        hasRestoredSession = true;
      } catch (_) {
        _turnManager = state.isQuickMode || _teamsCubit == null
            ? null
            : TurnManager.randomStart(
                teams: _usesPlayers
                    ? playerTeams(_teamsCubit.state.players)
                    : _teamsCubit.state.teams,
                totalRounds: _setup?.totalRounds ?? 3,
              );
      }
    }
    _sessionReady = true;
    if (!hasRestoredSession) _persist();
  }

  void _persist() {
    if (!_sessionReady) return;
    _session.save({
      'startingScores': _startingScores,
      'isQuickMode': state.isQuickMode,
      'participationMode': _usesPlayers
          ? GameParticipationMode.players.name
          : GameParticipationMode.teams.name,
      'stats': _stats.toJson(),
      'manager': _session.encodeManager(_turnManager),
      'item': state.currentTopic?.toJson(),
      'remainingMs': _clock.remaining.inMilliseconds,
      'elapsedSeconds': state.elapsedSeconds,
      'hiddenBombDuration': state.hiddenBombDuration,
      'isExploded': state.isExploded,
      'isFuseExpired': state.isFuseExpired,
      'isReadyPhase': state.isReadyPhase,
      'turnPassCount': state.turnPassCount,
      'holdingTeamOrPlayer': state.holdingTeamOrPlayer,
      'loserName': state.loserName,
      'currentRound': state.currentRound,
      'totalRounds': state.totalRounds,
      'completedRounds': _completedRounds,
      'isGameOver': state.isGameOver,
    });
  }

  @override
  void emit(HotPotatoState state) {
    super.emit(state);
    _persist();
  }

  void finishAndClear() => _session.clear();

  void startNewRound() {
    final topic = _repository.getNextTopic();
    final randomSeconds = 18 + _random.nextInt(21);
    if (_turnManager != null &&
        _turnManager!.teams.length > 1 &&
        _completedRounds > 0) {
      final offset = 1 + _random.nextInt(_turnManager!.teams.length - 1);
      final nextIndex =
          (_turnManager!.currentTeamIndex + offset) %
          _turnManager!.teams.length;
      _turnManager = _turnManager!.withCurrentTeamIndex(nextIndex);
    }

    emit(
      state.copyWith(
        currentTopic: topic,
        elapsedSeconds: 0,
        hiddenBombDuration: randomSeconds,
        isExploded: false,
        isTicking: true,
        isFuseExpired: false,
        isReadyPhase: false,
        turnPassCount: 0,
        holdingTeamOrPlayer:
            _turnManager?.currentTeam.name ?? state.holdingTeamOrPlayer,
        clearLoser: true,
      ),
    );
    _pulseSchedule.reset();

    _clock.start(Duration(seconds: randomSeconds));
  }

  void _onClockChanged(Duration remaining) {
    final elapsedMs =
        state.hiddenBombDuration * 1000 - remaining.inMilliseconds;
    final elapsed = (elapsedMs / 1000).floor();
    final tension = (elapsedMs / (state.hiddenBombDuration * 1000)).clamp(
      0.0,
      1.0,
    );
    // The fuse begins restrained and becomes sharply more urgent near the end.
    if (remaining > Duration.zero &&
        _pulseSchedule.shouldPulse(elapsedMs, tension)) {
      _audio.playBombTick(tension);
      if (tension > .82) _haptics.mediumBump();
    }
    if (elapsed != state.elapsedSeconds) {
      emit(state.copyWith(elapsedSeconds: elapsed));
    }
  }

  void _explodeBomb() {
    _audio.playBoom();
    _haptics.heavyBoom();

    final loser = state.holdingTeamOrPlayer;
    _stats.add(loser, GameStatMetric.explosion);

    if (!state.isQuickMode && _turnManager != null) {
      final losingTeam = _turnManager!.currentTeam;
      if (!_usesPlayers) {
        _teamsCubit?.updateTeamScore(losingTeam.id, -2);
      }
      _turnManager = _turnManager!.updateTeamScore(losingTeam.id, -2);
    }

    _completedRounds++;
    if (!state.isQuickMode && _completedRounds >= state.totalRounds) {
      _session.complete(_turnManager, baseline: _startingScores);
    }
    emit(
      state.copyWith(
        isExploded: true,
        isTicking: false,
        isFuseExpired: false,
        loserName: loser,
        isGameOver: !state.isQuickMode && _completedRounds >= state.totalRounds,
        currentRound: _completedRounds.clamp(1, state.totalRounds),
      ),
    );
  }

  void _onFuseFinished() {
    if (state.turnPassCount >= _participantCount) {
      _explodeBomb();
      return;
    }
    // The hidden fuse has ended, but nobody is excluded from this round.
    // Explosion occurs immediately after every participant has held the bomb.
    emit(state.copyWith(isFuseExpired: true));
  }

  void passToNext() {
    if (state.isExploded || !state.isTicking) return;

    _haptics.lightClick();
    _audio.playTurn();
    String nextName;

    if (!state.isQuickMode && _turnManager != null) {
      _turnManager = _turnManager!.nextTeam();
      nextName = _turnManager!.currentTeam.name;
    } else {
      nextName = 'بازیکن ${(state.turnPassCount % 4) + 2}';
    }

    final nextPassCount = state.turnPassCount + 1;
    emit(
      state.copyWith(
        turnPassCount: nextPassCount,
        holdingTeamOrPlayer: nextName,
      ),
    );
    if (state.isFuseExpired && nextPassCount >= _participantCount) {
      _explodeBomb();
    }
  }

  void showMatchResult() {
    emit(state.copyWith(isExploded: false, isGameOver: true));
  }

  void prepareNextRound() {
    emit(
      state.copyWith(isExploded: false, isReadyPhase: true, clearLoser: true),
    );
  }

  void pause() {
    if (!state.isTicking || state.isExploded || state.isGameOver) return;
    _clock.pause();
    emit(state.copyWith(isTicking: false));
  }

  void resume() {
    if (state.isTicking ||
        state.isExploded ||
        state.isReadyPhase ||
        state.isGameOver) {
      return;
    }
    emit(state.copyWith(isTicking: true));
    if (!state.isFuseExpired) _clock.resume();
  }

  @override
  Future<void> close() {
    _clock.dispose();
    return super.close();
  }
}
