import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/haptics_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/charades/data/charades_repository.dart';
import 'charades_state.dart';

class CharadesCubit extends Cubit<CharadesState> {
  final CharadesRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  Timer? _timer;
  TurnManager? _turnManager;

  CharadesCubit({
    required CharadesRepository repository,
    bool isQuickMode = false,
    TeamsCubit? teamsCubit,
  })  : _repository = repository,
        super(CharadesState(isQuickMode: isQuickMode)) {
    if (!isQuickMode && teamsCubit != null) {
      _turnManager = TurnManager(
        teams: teamsCubit.state.teams,
        totalRounds: 3,
      );
      emit(state.copyWith(
        activeTeamName: _turnManager!.currentTeam.name,
        activeTeamIndex: _turnManager!.currentTeamIndex,
        currentRound: _turnManager!.currentRound,
        totalRounds: _turnManager!.totalRounds,
      ));
    } else {
      emit(state.copyWith(activeTeamName: 'حالت آزاد', isPassPhonePhase: false));
      startRound();
    }
  }

  void startRound() {
    final nextWord = _repository.getNextWord();
    emit(state.copyWith(
      currentWord: nextWord,
      remainingSeconds: state.totalSeconds,
      isTimerRunning: true,
      isRoundOver: false,
      isPassPhonePhase: false,
      isSecretRevealed: true,
      correctCount: 0,
      skipCount: 0,
      roundScore: 0,
    ));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        emit(state.copyWith(remainingSeconds: state.remainingSeconds - 1));
        if (state.remainingSeconds <= 5) {
          _audio.playTick();
          _haptics.lightClick();
        }
      } else {
        _timer?.cancel();
        _onTimeFinished();
      }
    });
  }

  void _onTimeFinished() {
    _audio.playBuzzer();
    _haptics.buzzerFail();

    if (!state.isQuickMode && _turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      sl<TeamsCubit>().updateTeamScore(activeTeam.id, state.roundScore);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, state.roundScore);
    }

    emit(state.copyWith(
      remainingSeconds: 0,
      isTimerRunning: false,
      isRoundOver: true,
    ));
  }

  void onCorrect() {
    if (!state.isTimerRunning) return;
    final earnedPoints = state.currentWord?.points ?? 1;
    _audio.playCorrect();
    _haptics.lightClick();

    final nextWord = _repository.getNextWord();
    emit(state.copyWith(
      correctCount: state.correctCount + 1,
      roundScore: state.roundScore + earnedPoints,
      currentWord: nextWord,
    ));
  }

  void onSkip() {
    if (!state.isTimerRunning) return;
    _haptics.lightClick();
    final nextWord = _repository.getNextWord();
    emit(state.copyWith(
      skipCount: state.skipCount + 1,
      currentWord: nextWord,
    ));
  }

  void togglePause() {
    if (state.isTimerRunning) {
      _timer?.cancel();
      emit(state.copyWith(isTimerRunning: false));
    } else if (!state.isRoundOver && !state.isPassPhonePhase) {
      _startTimer();
      emit(state.copyWith(isTimerRunning: true));
    }
  }

  void nextTurn() {
    if (_turnManager != null) {
      _turnManager = _turnManager!.nextTurn();
      emit(state.copyWith(
        activeTeamName: _turnManager!.currentTeam.name,
        activeTeamIndex: _turnManager!.currentTeamIndex,
        currentRound: _turnManager!.currentRound,
        isRoundOver: false,
        isPassPhonePhase: true,
        isSecretRevealed: false,
      ));
    } else {
      startRound();
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
