import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/haptics_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/five_seconds/data/five_seconds_repository.dart';
import 'five_seconds_state.dart';

class FiveSecondsCubit extends Cubit<FiveSecondsState> {
  final FiveSecondsRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  Timer? _timer;
  TurnManager? _turnManager;

  FiveSecondsCubit({
    required FiveSecondsRepository repository,
    bool isQuickMode = false,
    TeamsCubit? teamsCubit,
  })  : _repository = repository,
        super(FiveSecondsState(isQuickMode: isQuickMode)) {
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
      startQuestion();
    }
  }

  void startQuestion() {
    final nextQ = _repository.getNextQuestion();
    emit(state.copyWith(
      currentQuestion: nextQ,
      remainingSeconds: 5,
      isTimerRunning: true,
      isCountdownFinished: false,
      isPassPhonePhase: false,
    ));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        emit(state.copyWith(remainingSeconds: state.remainingSeconds - 1));
        _audio.playTick();
        _haptics.lightClick();
      } else {
        _timer?.cancel();
        _audio.playBuzzer();
        _haptics.buzzerFail();
        emit(state.copyWith(
          remainingSeconds: 0,
          isTimerRunning: false,
          isCountdownFinished: true,
        ));
      }
    });
  }

  void onSuccess() {
    _audio.playCorrect();
    _haptics.lightClick();

    if (!state.isQuickMode && _turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      sl<TeamsCubit>().updateTeamScore(activeTeam.id, 1);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, 1);
    }

    emit(state.copyWith(
      successCount: state.successCount + 1,
      roundScore: state.roundScore + 1,
    ));
    nextTurn();
  }

  void onFail() {
    _audio.playBuzzer();
    _haptics.buzzerFail();

    emit(state.copyWith(
      failCount: state.failCount + 1,
    ));
    nextTurn();
  }

  void nextTurn() {
    if (_turnManager != null) {
      _turnManager = _turnManager!.nextTurn();
      emit(state.copyWith(
        activeTeamName: _turnManager!.currentTeam.name,
        activeTeamIndex: _turnManager!.currentTeamIndex,
        currentRound: _turnManager!.currentRound,
        isPassPhonePhase: true,
        isCountdownFinished: false,
        isTimerRunning: false,
      ));
    } else {
      startQuestion();
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
