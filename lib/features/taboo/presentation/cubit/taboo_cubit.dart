import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/haptics_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/taboo/data/taboo_repository.dart';
import 'taboo_state.dart';

class TabooCubit extends Cubit<TabooState> {
  final TabooRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  Timer? _timer;
  TurnManager? _turnManager;

  TabooCubit({
    required TabooRepository repository,
    bool isQuickMode = false,
    TeamsCubit? teamsCubit,
  })  : _repository = repository,
        super(TabooState(isQuickMode: isQuickMode)) {
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
      emit(state.copyWith(
        activeTeamName: 'حالت آزاد',
        isPassPhonePhase: false,
      ));
      startRound();
    }
  }

  void startRound() {
    final nextCard = _repository.getNextCard();
    emit(state.copyWith(
      currentCard: nextCard,
      remainingSeconds: state.totalSeconds,
      isTimerRunning: true,
      isRoundOver: false,
      isPassPhonePhase: false,
      correctCount: 0,
      foulCount: 0,
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
    _audio.playCorrect();
    _haptics.lightClick();
    final nextCard = _repository.getNextCard();
    emit(state.copyWith(
      correctCount: state.correctCount + 1,
      roundScore: state.roundScore + 1,
      currentCard: nextCard,
    ));
  }

  void onFoul() {
    if (!state.isTimerRunning) return;
    _audio.playBuzzer();
    _haptics.buzzerFail();
    final nextCard = _repository.getNextCard();
    emit(state.copyWith(
      foulCount: state.foulCount + 1,
      roundScore: state.roundScore - 1,
      currentCard: nextCard,
    ));
  }

  void onSkip() {
    if (!state.isTimerRunning) return;
    _haptics.lightClick();
    final nextCard = _repository.getNextCard();
    emit(state.copyWith(
      skipCount: state.skipCount + 1,
      currentCard: nextCard,
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
