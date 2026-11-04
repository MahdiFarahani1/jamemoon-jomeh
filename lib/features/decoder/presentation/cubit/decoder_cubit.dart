import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/team_model.dart';
import '../../data/decoder_repository.dart';
import 'decoder_state.dart';

class DecoderCubit extends Cubit<DecoderState> {
  final DecoderRepository repository;
  Future<void> _writes = Future.value();
  bool _starting = false;

  DecoderCubit({required this.repository, bool resumeSaved = false})
    : super(DecoderState()) {
    final restored = resumeSaved ? repository.restore() : null;
    if (restored != null) {
      emit(restored);
      if (restored.winner != null) _record(restored);
    }
  }

  void _track(Future<void> write) {
    _writes = Future.wait<void>([_writes, write])
        .then((_) {})
        .catchError((Object _) {});
  }

  // StorageService updates its in-memory snapshot synchronously and serializes disk writes.
  void _save(DecoderState snapshot) => _track(repository.save(snapshot));
  void _record(DecoderState snapshot) =>
      _track(repository.recordResult(snapshot));
  void _change(DecoderState next) {
    emit(next);
    _save(next);
  }

  void selectTeam(int slot, String id) {
    if (state.phase != DecoderPhase.setup) return;
    emit(
      slot == 0
          ? state.copyWith(selectedFirst: id, clearError: true)
          : state.copyWith(selectedSecond: id, clearError: true),
    );
    clearRosterError();
  }

  void showRosterError(String message) =>
      emit(state.copyWith(rosterError: message));

  void clearRosterError() {
    if (state.rosterError != null) {
      emit(state.copyWith(clearRosterError: true));
    }
  }

  Future<void> startGame(Team first, Team second) async {
    if (_starting || first.id == second.id) return;
    _starting = true;
    try {
      final next = await repository.newGame(first, second);
      if (!isClosed) _change(next);
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(error: 'دریافت واژه‌ها ممکن نشد؛ دوباره تلاش کنید.'),
        );
      }
    } finally {
      _starting = false;
    }
  }

  void dismissShield() {
    if (state.phase != DecoderPhase.shield) return;
    _change(state.copyWith(phase: state.shieldTarget, mapVisible: false));
  }

  void shield() {
    if (state.phase == DecoderPhase.setup ||
        state.phase == DecoderPhase.shield) {
      return;
    }
    _change(
      state.copyWith(
        phase: DecoderPhase.shield,
        shieldTarget: state.phase,
        mapVisible: false,
      ),
    );
  }

  void showMap() {
    if (state.phase == DecoderPhase.guide && !state.mapVisible) {
      emit(state.copyWith(mapVisible: true));
    }
  }

  void hideMap() {
    if (state.phase == DecoderPhase.guide && state.mapVisible) {
      emit(state.copyWith(mapVisible: false));
    }
  }

  void submitClue(String raw, String number) {
    if (state.phase != DecoderPhase.guide || state.mapVisible) return;
    final clue = raw.trim();
    final normalized = normalizeDecoderWord(clue);
    final count = int.tryParse(
      number.trim().replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (m) {
        final code = m[0]!.codeUnitAt(0);
        return '${code >= 0x6f0 ? code - 0x6f0 : code - 0x660}';
      }),
    );
    if (clue.isEmpty ||
        !isDecoderWord(clue) ||
        count == null ||
        count <= 0 ||
        count >= 2147483647 ||
        state.cards.any((c) => normalizeDecoderWord(c.word) == normalized)) {
      emit(
        state.copyWith(
          error: 'یک کلمه متفاوت از واژه‌های صفحه و یک عدد مثبت وارد کنید.',
        ),
      );
      return;
    }
    _change(
      state.copyWith(
        phase: DecoderPhase.shield,
        shieldTarget: DecoderPhase.guessing,
        clue: clue,
        clueCount: count,
        guessesLeft: count + 1,
        mapVisible: false,
        clearError: true,
      ),
    );
  }

  void guess(int index) {
    if (state.phase != DecoderPhase.guessing ||
        index < 0 ||
        index >= state.cards.length ||
        state.cards[index].revealed) {
      return;
    }
    final cards = List<DecoderCard>.of(state.cards);
    final card = cards[index];
    cards[index] = card.reveal();
    int? winner;
    if (card.role == DecoderRole.hazard) {
      winner = 1 - state.activeTeam;
    } else {
      for (var i = 0; i < 2; i++) {
        final role = i == 0 ? DecoderRole.team0 : DecoderRole.team1;
        if (cards.where((c) => c.role == role).every((c) => c.revealed)) {
          winner = i;
        }
      }
    }
    if (winner != null) {
      final result = state.copyWith(
        cards: cards,
        phase: DecoderPhase.result,
        winner: winner,
        guessesLeft: 0,
      );
      _change(result);
      _record(result);
      return;
    }
    final left = state.guessesLeft - 1;
    final ownRole = state.activeTeam == 0
        ? DecoderRole.team0
        : DecoderRole.team1;
    if (card.role != ownRole || left == 0) {
      _change(
        state.copyWith(
          cards: cards,
          activeTeam: 1 - state.activeTeam,
          phase: DecoderPhase.reveal,
          shieldTarget: DecoderPhase.guide,
          clue: '',
          clueCount: 0,
          guessesLeft: 0,
        ),
      );
    } else {
      _change(state.copyWith(cards: cards, guessesLeft: left));
    }
  }

  void continueTurn() {
    if (state.phase != DecoderPhase.reveal) return;
    _change(
      state.copyWith(
        phase: DecoderPhase.shield,
        shieldTarget: DecoderPhase.guide,
      ),
    );
  }

  void endTurn() {
    if (state.phase != DecoderPhase.guessing) return;
    _change(
      state.copyWith(
        activeTeam: 1 - state.activeTeam,
        phase: DecoderPhase.shield,
        shieldTarget: DecoderPhase.guide,
        clue: '',
        clueCount: 0,
        guessesLeft: 0,
      ),
    );
  }

  void reset() {
    if (state.phase != DecoderPhase.result) return;
    emit(DecoderState());
    _track(repository.save(null));
  }

  @override
  Future<void> close() async {
    await _writes;
    return super.close();
  }
}
