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
import '../../data/charades_repository.dart';
import '../../data/charades_word_model.dart';
import 'charades_state.dart';

class CharadesCubit extends Cubit<CharadesState> {
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
  final GameSessionStore _session = GameSessionStore('charades');
  bool _sessionReady = false;
  bool hasRestoredSession = false;
  final CharadesRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  late final RoundClock _clock = RoundClock(
    onChanged: _onClockChanged,
    onFinished: _onTimeFinished,
  );
  TurnManager? _turnManager;
  final TeamsCubit? _teamsCubit;
  final GameSetupConfig? _setup;
  String _category = 'all';
  String get selectedCategory => _category;
  bool _finished = false;
  String get _actorName {
    if (_turnManager == null || _teamsCubit == null) {
      return state.activeTeamName;
    }
    return currentAssignment?.performer ?? _turnManager!.currentTeam.name;
  }

  CharadesCubit({
    required CharadesRepository repository,
    GameSetupConfig? setup,
    bool isQuickMode = false,
    bool resumeSaved = false,
    TeamsCubit? teamsCubit,
  }) : _repository = repository,
       _teamsCubit = teamsCubit,
       _setup = setup,
       super(
         CharadesState(
           isQuickMode: isQuickMode,
           totalSeconds: setup?.roundSeconds ?? 60,
         ),
       ) {
    _category = setup?.charadesCategory ?? 'all';
    if (!_repository.hasCategory(_category)) _category = 'all';
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
        final savedCategory = data['charadesCategory'];
        if (savedCategory is String && _repository.hasCategory(savedCategory)) {
          _category = savedCategory;
        }
        final savedItem = rawItem == null
            ? null
            : CharadesWord.fromJson(Map<String, dynamic>.from(rawItem as Map));
        final item = savedItem == null
            ? null
            : _repository.findById(savedItem.id) ?? savedItem;
        if (item != null && !CharadesWord.isValid(item.word)) {
          throw const FormatException(
            'واژهٔ ذخیره‌شده با قوانین جدید سازگار نیست.',
          );
        }
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
            isSecretRevealed: data['isSecretRevealed'] as bool,
            roundScore: data['roundScore'] as int,
            correctCount: data['correctCount'] as int,
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
        _category = _setup?.charadesCategory ?? 'all';
        if (!_repository.hasCategory(_category)) _category = 'all';
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
      'charadesCategory': _category,
      'isQuickMode': state.isQuickMode,
      'stats': _stats.toJson(),
      'manager': _session.encodeManager(_turnManager),
      'item': state.currentWord?.toJson(),
      'remainingMs': _clock.remaining.inMilliseconds,
      'isRoundOver': state.isRoundOver,
      'isPassPhonePhase': state.isPassPhonePhase,
      'isSecretRevealed': state.isSecretRevealed,
      'roundScore': state.roundScore,
      'correctCount': state.correctCount,
      'skipCount': state.skipCount,
      'isGameOver': _finished,
    });
  }

  @override
  void emit(CharadesState state) {
    super.emit(state);
    _persist();
  }

  void finishAndClear() => _session.clear();

  void startRound() {
    if (state.isTimerRunning || _finished) return;
    final nextWord = _repository.getNextWord(category: _category);
    emit(
      state.copyWith(
        currentWord: nextWord,
        remainingSeconds: state.totalSeconds,
        isTimerRunning: true,
        isRoundOver: false,
        isPassPhonePhase: false,
        isSecretRevealed: true,
        correctCount: 0,
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
    if (!state.isTimerRunning ||
        state.isRoundOver ||
        _finished ||
        state.currentWord == null) {
      return;
    }
    _audio.playCorrect();
    _haptics.lightClick();
    _stats.add(_actorName, GameStatMetric.correct);

    final points = state.currentWord!.points;
    if (_turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      _teamsCubit?.updateTeamScore(activeTeam.id, points);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, points);
    }

    final nextWord = _repository.getNextWord(category: _category);
    emit(
      state.copyWith(
        currentWord: nextWord,
        correctCount: state.correctCount + 1,
        roundScore: state.roundScore + points,
      ),
    );
  }

  void onSkip() {
    if (!state.isTimerRunning || state.isRoundOver || _finished) return;
    _audio.playSkip();
    _haptics.lightClick();
    _stats.add(_actorName, GameStatMetric.skip);
    final nextWord = _repository.getNextWord(category: _category);
    emit(state.copyWith(currentWord: nextWord, skipCount: state.skipCount + 1));
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
    emit(state.copyWith(isTimerRunning: true, isSecretRevealed: true));
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
