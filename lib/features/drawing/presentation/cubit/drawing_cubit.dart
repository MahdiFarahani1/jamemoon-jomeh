import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/haptics_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/drawing/data/drawing_repository.dart';
import 'drawing_state.dart';

class DrawingCubit extends Cubit<DrawingState> {
  final DrawingRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  Timer? _timer;
  TurnManager? _turnManager;

  DrawingCubit({
    required DrawingRepository repository,
    bool isQuickMode = false,
    TeamsCubit? teamsCubit,
  })  : _repository = repository,
        super(DrawingState(isQuickMode: isQuickMode)) {
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
      prepareWord();
    }
  }

  void prepareWord() {
    final nextWord = _repository.getNextWord();
    emit(state.copyWith(
      currentWord: nextWord,
      isPassPhonePhase: false,
      isWordRevealed: true,
      isRoundOver: false,
      isTimerRunning: false,
      strokes: [],
    ));
  }

  void startDrawingOnCanvas() {
    emit(state.copyWith(
      isWordRevealed: false,
      isTimerRunning: true,
      remainingSeconds: state.totalSeconds,
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

    emit(state.copyWith(
      remainingSeconds: 0,
      isTimerRunning: false,
      isRoundOver: true,
    ));
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
    _timer?.cancel();
    _audio.playCorrect();
    _haptics.lightClick();

    if (!state.isQuickMode && _turnManager != null) {
      final activeTeam = _turnManager!.currentTeam;
      sl<TeamsCubit>().updateTeamScore(activeTeam.id, 2);
      _turnManager = _turnManager!.updateTeamScore(activeTeam.id, 2);
    }

    emit(state.copyWith(
      roundScore: state.roundScore + 2,
      isTimerRunning: false,
      isRoundOver: true,
    ));
  }

  void nextTurn() {
    if (_turnManager != null) {
      _turnManager = _turnManager!.nextTurn();
      emit(state.copyWith(
        activeTeamName: _turnManager!.currentTeam.name,
        activeTeamIndex: _turnManager!.currentTeamIndex,
        currentRound: _turnManager!.currentRound,
        isPassPhonePhase: true,
        isWordRevealed: false,
        isRoundOver: false,
        strokes: [],
      ));
    } else {
      prepareWord();
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
