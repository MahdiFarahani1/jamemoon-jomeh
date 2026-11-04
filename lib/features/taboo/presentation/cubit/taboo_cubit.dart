import 'dart:async';

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
import '../../data/taboo_card_model.dart';
import '../../data/taboo_repository.dart';
import 'taboo_state.dart';

class TabooCubit extends Cubit<TabooState> {
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
  final GameSessionStore _session = GameSessionStore('taboo');
  bool _sessionReady = false;
  bool hasRestoredSession = false;
  final TabooRepository _repository;
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

  TabooCubit({
    required TabooRepository repository,
    GameSetupConfig? setup,
    bool isQuickMode = false,
    bool resumeSaved = false,
    TeamsCubit? teamsCubit,
  }) : _repository = repository,
       _teamsCubit = teamsCubit,
       _setup = setup,
       super(
         TabooState(
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
            : TabooCard.fromJson(Map<String, dynamic>.from(rawItem as Map));
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
            currentCard: item,
            remainingSeconds: (remainingMs / 1000).ceil(),
            isTimerRunning: false,
            isRoundOver: data['isRoundOver'] as bool,
            isPassPhonePhase: data['isPassPhonePhase'] == true || item == null,
            roundScore: data['roundScore'] as int,
            correctCount: data['correctCount'] as int,
            foulCount: data['foulCount'] as int,
            skipCount: data['skipCount'] as int,
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
      'item': state.currentCard?.toJson(),
      'remainingMs': _clock.remaining.inMilliseconds,
      'isRoundOver': state.isRoundOver,
      'isPassPhonePhase': state.isPassPhonePhase,
      'roundScore': state.roundScore,
      'correctCount': state.correctCount,
      'foulCount': state.foulCount,
      'skipCount': state.skipCount,
      'isGameOver': _finished,
    });
  }

  @override
  void emit(TabooState state) {
    super.emit(state);
    _persist();
  }

  void finishAndClear() => _session.clear();

  void startRound() {
    if (state.isTimerRunning || _finished) return;
    final nextCard = _repository.getNextCard();
    emit(
      state.copyWith(
        currentCard: nextCard,
        remainingSeconds: state.totalSeconds,
        isTimerRunning: true,
        isRoundOver: false,
        isPassPhonePhase: false,
        correctCount: 0,
        foulCount: 0,
        skipCount: 0,
        roundScore: 0,
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
    emit(state.copyWith(isTimerRunning: false, isRoundOver: true));
  }

  void onCorrect() {
    if (!state.isTimerRunning || state.isRoundOver || _finished) return;
    _audio.playCorrect();
    _haptics.lightClick();
    _stats.add(_actorName, GameStatMetric.correct);

    if (!state.isQuickMode && _turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      _teamsCubit?.updateTeamScore(activeTeam.id, 1);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, 1);
    }

    final nextCard = _repository.getNextCard();
    emit(
      state.copyWith(
        currentCard: nextCard,
        correctCount: state.correctCount + 1,
        roundScore: state.roundScore + 1,
      ),
    );
  }

  void onFoul() {
    if (!state.isTimerRunning || state.isRoundOver || _finished) return;
    _audio.playBuzzer();
    _haptics.buzzerFail();
    _stats.add(_actorName, GameStatMetric.foul);

    if (!state.isQuickMode && _turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      _teamsCubit?.updateTeamScore(activeTeam.id, -1);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, -1);
    }

    final nextCard = _repository.getNextCard();
    emit(
      state.copyWith(
        currentCard: nextCard,
        foulCount: state.foulCount + 1,
        roundScore: state.roundScore - 1,
      ),
    );
  }

  void onSkip() {
    if (!state.isTimerRunning || state.isRoundOver || _finished) return;
    _audio.playSkip();
    _haptics.lightClick();
    _stats.add(_actorName, GameStatMetric.skip);
    final nextCard = _repository.getNextCard();
    emit(state.copyWith(currentCard: nextCard, skipCount: state.skipCount + 1));
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
    if (!state.isRoundOver || _finished) return;
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
          isPassPhonePhase: true,
          isRoundOver: false,
          activeTeamName: _turnManager!.currentTeam.name,
          activeTeamIndex: _turnManager!.currentTeamIndex,
          currentRound: _turnManager!.currentRound,
          totalRounds: _turnManager!.totalRounds,
          roundScore: 0,
          correctCount: 0,
          foulCount: 0,
          skipCount: 0,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isPassPhonePhase: true,
          isRoundOver: false,
          roundScore: 0,
          correctCount: 0,
          foulCount: 0,
          skipCount: 0,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _clock.dispose();
    return super.close();
  }
}
