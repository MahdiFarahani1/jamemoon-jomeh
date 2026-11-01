import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/models/turn_manager.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/haptics_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/hot_potato/data/hot_potato_repository.dart';
import 'hot_potato_state.dart';

class HotPotatoCubit extends Cubit<HotPotatoState> {
  final HotPotatoRepository _repository;
  final AudioService _audio = sl<AudioService>();
  final HapticsService _haptics = sl<HapticsService>();
  final Random _random = Random();
  Timer? _timer;
  TurnManager? _turnManager;

  HotPotatoCubit({
    required HotPotatoRepository repository,
    bool isQuickMode = false,
    TeamsCubit? teamsCubit,
  })  : _repository = repository,
        super(HotPotatoState(isQuickMode: isQuickMode)) {
    if (!isQuickMode && teamsCubit != null) {
      _turnManager = TurnManager(
        teams: teamsCubit.state.teams,
        totalRounds: 3,
      );
      emit(state.copyWith(
        holdingTeamOrPlayer: _turnManager!.currentTeam.name,
        currentRound: _turnManager!.currentRound,
        totalRounds: _turnManager!.totalRounds,
      ));
    }
    startNewRound();
  }

  void startNewRound() {
    _timer?.cancel();
    final topic = _repository.getNextTopic();
    final randomSeconds = 18 + _random.nextInt(21);

    emit(state.copyWith(
      currentTopic: topic,
      elapsedSeconds: 0,
      hiddenBombDuration: randomSeconds,
      isExploded: false,
      isTicking: true,
      turnPassCount: 0,
      loserName: null,
    ));

    _startBombTicker();
  }

  void _startBombTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newElapsed = state.elapsedSeconds + 1;
      emit(state.copyWith(elapsedSeconds: newElapsed));

      _audio.playTick();
      if (newElapsed > state.hiddenBombDuration * 0.7) {
        _haptics.mediumBump();
      }

      if (newElapsed >= state.hiddenBombDuration) {
        _timer?.cancel();
        _explodeBomb();
      }
    });
  }

  void _explodeBomb() {
    _audio.playBoom();
    _haptics.heavyBoom();

    final loser = state.holdingTeamOrPlayer;

    if (!state.isQuickMode && _turnManager != null) {
      final losingTeam = _turnManager!.currentTeam;
      sl<TeamsCubit>().updateTeamScore(losingTeam.id, -2);
    }

    emit(state.copyWith(
      isExploded: true,
      isTicking: false,
      loserName: loser,
    ));
  }

  void passToNext() {
    if (state.isExploded || !state.isTicking) return;

    _haptics.lightClick();
    String nextName;

    if (!state.isQuickMode && _turnManager != null) {
      _turnManager = _turnManager!.nextTurn();
      nextName = _turnManager!.currentTeam.name;
    } else {
      nextName = 'بازیکن ${(state.turnPassCount % 4) + 2}';
    }

    emit(state.copyWith(
      turnPassCount: state.turnPassCount + 1,
      holdingTeamOrPlayer: nextName,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
