import 'dart:async';

import 'package:flutter/material.dart';
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
import '../../data/drawing_repository.dart';
import '../../data/drawing_word_model.dart';
import 'drawing_state.dart';

class DrawingCubit extends Cubit<DrawingState> {
  int get playerOrderSeed => _session.sessionId.hashCode;
  bool get isFinalTurn =>
      !state.isQuickMode && _turnManager?.isFinalTurn == true;
  PlayerTurnAssignment? get currentAssignment =>
      _turnManager == null || _teamsCubit == null
      ? null
      : PlayerTurnAssignment.forTeam(
          teams: _teamsCubit.state.teams,
          players: _teamsCubit.state.players,
          teamName: _turnManager!.currentTeam.name,
          round: _turnManager!.currentTeamTurnNumber,
          seed: playerOrderSeed,
        );
  GameResult? get result => GameResult.fromManager(
    _turnManager,
    baseline: _startingScores,
    highlights: _stats.highlights(),
  );
  final GameStatsTracker _stats = GameStatsTracker();
  Map<String, int> _startingScores = {};
  final GameSessionStore _session = GameSessionStore('drawing');
  bool _sessionReady = false;
  bool hasRestoredSession = false;
  final DrawingRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  late final RoundClock _clock = RoundClock(
    onChanged: _onClockChanged,
    onFinished: _onTimeFinished,
  );
  TurnManager? _turnManager;
  final TeamsCubit? _teamsCubit;
  final GameSetupConfig? _setup;
  bool _finished = false;
  String get _actorName {
    if (_turnManager == null || _teamsCubit == null) {
      return state.activeTeamName;
    }
    return currentAssignment?.performer ?? _turnManager!.currentTeam.name;
  }

  DrawingCubit({
    required DrawingRepository repository,
    GameSetupConfig? setup,
    bool isQuickMode = false,
    bool resumeSaved = false,
    TeamsCubit? teamsCubit,
    String? tournamentId,
  }) : _repository = repository,
       _teamsCubit = teamsCubit,
       _setup = setup,
       super(
         DrawingState(
           isQuickMode: isQuickMode,
           totalSeconds: setup?.roundSeconds ?? 60,
         ),
       ) {
    if (!isQuickMode && teamsCubit != null) {
      _startingScores = {
        for (final team in teamsCubit.state.teams) team.id: team.score,
      };
      _turnManager = TurnManager.randomStart(
        teams: teamsCubit.state.teams,
        totalRounds: setup?.totalRounds ?? 3,
        turnsByTeamId: teamTurnCounts(
          teamsCubit.state.teams,
          teamsCubit.state.players,
        ),
      );
      emit(
        state.copyWith(
          activeTeamName: _turnManager!.currentTeam.name,
          activeTeamIndex: _turnManager!.currentTeamIndex,
          currentRound: _turnManager!.currentRound,
          totalRounds: _turnManager!.totalRounds,
        ),
      );
    } else {
      emit(state.copyWith(activeTeamName: 'تیم اول', isPassPhonePhase: true));
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
          _teamsCubit?.state.teams,
        );
        if (!state.isQuickMode && manager == null) {
          throw const FormatException();
        }
        final rawItem = data['item'];
        final item = rawItem == null
            ? null
            : DrawingWord.fromJson(Map<String, dynamic>.from(rawItem as Map));
        final remainingMs = data['remainingMs'] as int;
        if (remainingMs < 0 || remainingMs > state.totalSeconds * 1000) {
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
        _finished = data['isGameOver'] as bool;
        _clock.restore(Duration(milliseconds: remainingMs));
        super.emit(
          state.copyWith(
            currentWord: item,
            remainingSeconds: (remainingMs / 1000).ceil(),
            isTimerRunning: false,
            isRoundOver: data['isRoundOver'] as bool,
            isPassPhonePhase: data['isPassPhonePhase'] == true || item == null,
            isWordRevealed: data['isWordRevealed'] as bool,
            roundScore: data['roundScore'] as int,
            isGameOver: _finished,
            activeTeamName: manager?.currentTeam.name,
            activeTeamIndex: manager?.currentTeamIndex,
            currentRound: manager?.currentRound,
            totalRounds: manager?.totalRounds,
          ),
        );
        hasRestoredSession = true;
      } catch (_) {
        _turnManager = state.isQuickMode || _teamsCubit == null
            ? null
            : TurnManager.randomStart(
                teams: _teamsCubit.state.teams,
                totalRounds: _setup?.totalRounds ?? 3,
                turnsByTeamId: teamTurnCounts(
                  _teamsCubit.state.teams,
                  _teamsCubit.state.players,
                ),
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
      'roundSeconds': state.totalSeconds,
      'isQuickMode': state.isQuickMode,
      'stats': _stats.toJson(),
      'manager': _session.encodeManager(_turnManager),
      'item': state.currentWord?.toJson(),
      'remainingMs': _clock.remaining.inMilliseconds,
      'isRoundOver': state.isRoundOver,
      'isPassPhonePhase': state.isPassPhonePhase,
      'isWordRevealed': state.isWordRevealed,
      'roundScore': state.roundScore,
      'isGameOver': _finished,
    });
  }

  @override
  void emit(DrawingState state) {
    super.emit(state);
    _persist();
  }

  void finishAndClear() => _session.clear();

  void prepareWord() {
    final nextWord = _repository.getNextWord();
    emit(
      state.copyWith(
        currentWord: nextWord,
        isPassPhonePhase: false,
        isWordRevealed: true,
        isRoundOver: false,
        isTimerRunning: false,
        strokes: [],
      ),
    );
  }

  void startDrawingOnCanvas() {
    emit(
      state.copyWith(
        isWordRevealed: false,
        isTimerRunning: true,
        remainingSeconds: state.totalSeconds,
      ),
    );
    _clock.start(Duration(seconds: state.totalSeconds));
  }

  void _onClockChanged(Duration remaining) {
    final secs = (remaining.inMilliseconds / 1000).ceil();
    if (secs != state.remainingSeconds) {
      emit(state.copyWith(remainingSeconds: secs));
      if (secs <= 5 && secs > 0) {
        _audio.playTick();
        _haptics.lightClick();
      }
    }
  }

  void _onTimeFinished() {
    _audio.playBuzzer();
    _haptics.buzzerFail();
    emit(
      state.copyWith(
        remainingSeconds: 0,
        isTimerRunning: false,
        isRoundOver: true,
      ),
    );
  }

  void addStroke(DrawnStroke stroke) {
    final updated = List<DrawnStroke>.from(state.strokes)..add(stroke);
    emit(state.copyWith(strokes: updated));
  }

  void undo() {
    if (state.strokes.isEmpty) return;
    final updated = List<DrawnStroke>.from(state.strokes)..removeLast();
    emit(state.copyWith(strokes: updated));
  }

  void clearCanvas() {
    emit(state.copyWith(strokes: []));
  }

  void setColor(Color color) {
    emit(state.copyWith(activeColor: color, isEraser: false));
  }

  void setStrokeWidth(double width) {
    emit(state.copyWith(strokeWidth: width));
  }

  void toggleEraser() {
    emit(state.copyWith(isEraser: !state.isEraser));
  }

  void onCorrectGuess() {
    if (!state.isTimerRunning || state.isRoundOver || _finished) return;
    _clock.pause();
    _stats.add(_actorName, GameStatMetric.correct);
    _audio.playCorrect();
    _haptics.lightClick();

    if (!state.isQuickMode && _turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      _teamsCubit?.updateTeamScore(activeTeam.id, 2);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, 2);
    }

    emit(
      state.copyWith(
        roundScore: state.roundScore + 2,
        isTimerRunning: false,
        isRoundOver: true,
      ),
    );
  }

  void pause() {
    if (!state.isTimerRunning || _finished) return;
    _clock.pause();
    emit(state.copyWith(isTimerRunning: false));
  }

  void resume() {
    if (state.isTimerRunning ||
        state.isRoundOver ||
        state.isPassPhonePhase ||
        _finished) {
      return;
    }
    emit(state.copyWith(isTimerRunning: true));
    _clock.resume();
  }

  void nextTurn() {
    if (_turnManager != null) {
      _turnManager = _turnManager!.nextTurn();
      if (_turnManager!.isGameOver) {
        _finished = true;
        _session.complete(_turnManager, baseline: _startingScores);
        emit(state.copyWith(isGameOver: true));
        return;
      }
      _audio.playTurn();
      emit(
        state.copyWith(
          activeTeamName: _turnManager!.currentTeam.name,
          activeTeamIndex: _turnManager!.currentTeamIndex,
          currentRound: _turnManager!.currentRound,
          isPassPhonePhase: true,
          isWordRevealed: false,
          isRoundOver: false,
          strokes: [],
        ),
      );
    } else {
      prepareWord();
    }
  }

  @override
  Future<void> close() {
    _clock.dispose();
    return super.close();
  }
}
