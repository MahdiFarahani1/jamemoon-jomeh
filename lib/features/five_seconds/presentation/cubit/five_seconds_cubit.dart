import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/models/turn_manager.dart';
import '../../../../core/models/game_result.dart';
import '../../../../core/models/game_setup_config.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/round_clock.dart';
import '../../../teams/presentation/cubit/teams_cubit.dart';
import '../../data/five_seconds_model.dart';
import '../../data/five_seconds_repository.dart';
import 'five_seconds_state.dart';

class FiveSecondsCubit extends Cubit<FiveSecondsState> {
  GameResult? get result =>
      GameResult.fromManager(_turnManager, baseline: _startingScores);
  Map<String, int> _startingScores = {};
  final GameSessionStore _session = GameSessionStore('five_seconds');
  bool _sessionReady = false;
  bool hasRestoredSession = false;
  final FiveSecondsRepository _repository;
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

  FiveSecondsCubit({
    required FiveSecondsRepository repository,
    GameSetupConfig? setup,
    bool isQuickMode = false,
    bool resumeSaved = false,
    TeamsCubit? teamsCubit,
  }) : _repository = repository,
       _teamsCubit = teamsCubit,
       _setup = setup,
       super(FiveSecondsState(isQuickMode: isQuickMode)) {
    if (!isQuickMode && teamsCubit != null) {
      _startingScores = {
        for (final team in teamsCubit.state.teams) team.id: team.score,
      };
      _turnManager = TurnManager(
        teams: teamsCubit.state.teams,
        totalRounds: setup?.totalRounds ?? 3,
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
            : FiveSecondsQuestion.fromJson(
                Map<String, dynamic>.from(rawItem as Map),
              );
        final remainingMs = data['remainingMs'] as int;
        if (remainingMs < 0 || remainingMs > 5000) {
          throw const FormatException();
        }
        _startingScores =
            (data['startingScores'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value as int),
            ) ??
            _startingScores;
        _turnManager = manager;
        _session.sessionId = data['sessionId'] as String;
        _finished = data['isGameOver'] as bool;
        _clock.restore(Duration(milliseconds: remainingMs));
        super.emit(
          state.copyWith(
            currentQuestion: item,
            remainingSeconds: (remainingMs / 1000).ceil(),
            isTimerRunning: false,
            isCountdownFinished: data['isCountdownFinished'] as bool,
            isPassPhonePhase: data['isPassPhonePhase'] == true || item == null,
            roundScore: data['roundScore'] as int,
            successCount: data['successCount'] as int,
            failCount: data['failCount'] as int,
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
            : TurnManager(
                teams: _teamsCubit.state.teams,
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
      'manager': _session.encodeManager(_turnManager),
      'item': state.currentQuestion?.toJson(),
      'remainingMs': _clock.remaining.inMilliseconds,
      'isCountdownFinished': state.isCountdownFinished,
      'isPassPhonePhase': state.isPassPhonePhase,
      'roundScore': state.roundScore,
      'successCount': state.successCount,
      'failCount': state.failCount,
      'isGameOver': _finished,
    });
  }

  @override
  void emit(FiveSecondsState state) {
    super.emit(state);
    _persist();
  }

  void finishAndClear() => _session.clear();

  void startQuestion() {
    final nextQ = _repository.getNextQuestion();
    emit(
      state.copyWith(
        currentQuestion: nextQ,
        remainingSeconds: 5,
        isTimerRunning: true,
        isCountdownFinished: false,
        isPassPhonePhase: false,
      ),
    );
    _clock.start(const Duration(seconds: 5));
  }

  void _onClockChanged(Duration remaining) {
    final secs = (remaining.inMilliseconds / 1000).ceil();
    if (secs != state.remainingSeconds) {
      emit(state.copyWith(remainingSeconds: secs));
      _audio.playTick();
      _haptics.lightClick();
    }
  }

  void _onTimeFinished() {
    _audio.playBuzzer();
    _haptics.buzzerFail();
    emit(
      state.copyWith(
        remainingSeconds: 0,
        isTimerRunning: false,
        isCountdownFinished: true,
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
        state.isPassPhonePhase ||
        state.isCountdownFinished ||
        _finished) {
      return;
    }
    emit(state.copyWith(isTimerRunning: true));
    _clock.resume();
  }

  void onSuccess() {
    if (!state.isCountdownFinished || state.isPassPhonePhase || _finished) {
      return;
    }
    emit(state.copyWith(isCountdownFinished: false));
    _audio.playCorrect();
    _haptics.lightClick();

    if (!state.isQuickMode && _turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      _teamsCubit?.updateTeamScore(activeTeam.id, 1);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, 1);
    }

    emit(
      state.copyWith(
        successCount: state.successCount + 1,
        roundScore: state.roundScore + 1,
      ),
    );
    nextTurn();
  }

  void onFail() {
    if (!state.isCountdownFinished || state.isPassPhonePhase || _finished) {
      return;
    }
    emit(state.copyWith(isCountdownFinished: false));
    _audio.playBuzzer();
    _haptics.buzzerFail();

    emit(state.copyWith(failCount: state.failCount + 1));
    nextTurn();
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
      emit(
        state.copyWith(
          activeTeamName: _turnManager!.currentTeam.name,
          activeTeamIndex: _turnManager!.currentTeamIndex,
          currentRound: _turnManager!.currentRound,
          isPassPhonePhase: true,
          isCountdownFinished: false,
          isTimerRunning: false,
        ),
      );
    } else {
      startQuestion();
    }
  }

  @override
  Future<void> close() {
    _clock.dispose();
    return super.close();
  }
}
