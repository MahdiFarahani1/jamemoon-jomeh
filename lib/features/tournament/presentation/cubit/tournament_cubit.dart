import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';

import 'tournament_state.dart';

class TournamentCubit extends Cubit<TournamentState> {
  final StorageService _storageService;
  final TeamsCubit _teamsCubit;

  TournamentCubit({
    required StorageService storageService,
    required TeamsCubit teamsCubit,
  }) : _storageService = storageService,
       _teamsCubit = teamsCubit,
       super(TournamentState(teams: teamsCubit.state.teams)) {
    _restoreActiveTournament();
  }

  void reloadFromStorage() => _restoreActiveTournament();

  void _restoreActiveTournament() {
    final activeData = _storageService.getActiveTournament();
    if (activeData != null) {
      final stageIndex = (activeData['currentStageIndex'] as int?) ?? 0;
      final isFinished = (activeData['isFinished'] as bool?) ?? false;
      emit(
        state.copyWith(
          currentStageIndex: stageIndex,
          isFinished: isFinished,
          teams: _teamsCubit.state.teams,
        ),
      );
    }
  }

  void startTournament() {
    _teamsCubit.resetAllScores();
    emit(
      state.copyWith(
        currentStageIndex: 0,
        isFinished: false,
        teams: _teamsCubit.state.teams,
      ),
    );
    _persistTournament();
  }

  void completeCurrentStage() {
    final nextIndex = state.currentStageIndex + 1;
    if (nextIndex >= state.stages.length) {
      emit(state.copyWith(isFinished: true, teams: _teamsCubit.state.teams));
    } else {
      emit(
        state.copyWith(
          currentStageIndex: nextIndex,
          teams: _teamsCubit.state.teams,
        ),
      );
    }
    _persistTournament();
  }

  void resetTournament() {
    _storageService.saveActiveTournament(null);
    _teamsCubit.resetAllScores();
    emit(
      state.copyWith(
        currentStageIndex: 0,
        isFinished: false,
        teams: _teamsCubit.state.teams,
      ),
    );
  }

  void _persistTournament() {
    _storageService.saveActiveTournament({
      'currentStageIndex': state.currentStageIndex,
      'isFinished': state.isFinished,
    });
  }
}
