import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/ranking.dart';
import '../../data/heist_catalog.dart';
import '../../domain/heist_models.dart';

class HeistCubit extends Cubit<HeistState> {
  HeistCubit({Random? random, bool resume = false})
    : _random = random ?? Random(),
      _storage = sl<StorageService>(),
      _audio = sl<AudioService>(),
      _haptics = sl<HapticsService>(),
      super(_restore(sl<StorageService>(), resume)) {
    if (state.sessionId.isEmpty) {
      emit(
        state.copyWith(
          sessionId: 'heist_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
    }
  }

  final Random _random;
  final StorageService _storage;
  final AudioService _audio;
  final HapticsService _haptics;

  static HeistState _restore(StorageService storage, bool resume) {
    if (!resume) return const HeistState();
    final saved = storage.getGameSession('heist');
    if (saved == null) return const HeistState();
    try {
      final restored = HeistState.fromJson(saved);
      // Secret pages always resume behind a pass-phone shield.
      if (restored.phase == HeistPhase.roleReveal) {
        return restored.copyWith(phase: HeistPhase.rolePass);
      }
      if (restored.phase == HeistPhase.secretChoice) {
        return restored.copyWith(phase: HeistPhase.secretPass);
      }
      if (restored.phase == HeistPhase.voteChoice) {
        return restored.copyWith(phase: HeistPhase.votePass);
      }
      return restored;
    } catch (_) {
      return const HeistState();
    }
  }

  HeistRole roleOf(HeistPlayer player) => HeistCatalog.role(player.roleId);
  HeistBank get currentBank => HeistCatalog.bank(state.bankId!);
  HeistEvent get currentEvent =>
      HeistCatalog.event(state.eventIds[state.eventIndex]);
  HeistPlayer get secretPlayer => state.players[state.secretIndex];
  HeistPlayer get rolePlayer => state.players[state.roleIndex];
  HeistPlayer get leader => state.players[state.leaderIndex];
  int get operationTarget =>
      currentBank.security + 2 + state.difficulty.modifier * 2;
  int get alarmLimit => 10 - state.difficulty.modifier * 2;

  @override
  void emit(HeistState state) {
    super.emit(state);
    if (state.phase != HeistPhase.setup) {
      _storage.saveGameSession('heist', state.toJson());
    }
  }

  void setPlayerCount(int count) {
    if (state.phase != HeistPhase.setup || count < 4 || count > 8) return;
    final names = List<String>.generate(
      count,
      (index) => index < state.names.length
          ? state.names[index]
          : 'بازیکن ${index + 1}',
    );
    emit(state.copyWith(names: names, clearMessage: true));
  }

  void renamePlayer(int index, String name) {
    if (state.phase != HeistPhase.setup ||
        index < 0 ||
        index >= state.names.length) {
      return;
    }
    final names = List<String>.of(state.names)..[index] = name;
    emit(state.copyWith(names: names, clearMessage: true));
  }

  void setDifficulty(HeistDifficulty difficulty) {
    if (state.phase == HeistPhase.setup) {
      emit(state.copyWith(difficulty: difficulty));
    }
  }

  void startGame() {
    final names = state.names.map((name) => name.trim()).toList();
    if (names.length < 4 ||
        names.length > 8 ||
        names.any((name) => name.isEmpty)) {
      emit(state.copyWith(message: 'نام 4 تا 8 بازیکن را کامل وارد کنید.'));
      return;
    }
    if (names.toSet().length != names.length) {
      emit(state.copyWith(message: 'نام بازیکن‌ها باید متفاوت باشد.'));
      return;
    }
    final roles = List<HeistRole>.of(HeistCatalog.roles)..shuffle(_random);
    final players = [
      for (var i = 0; i < names.length; i++)
        HeistPlayer(id: 'heist_player_$i', name: names[i], roleId: roles[i].id),
    ];
    _audio.playStart();
    emit(
      state.copyWith(
        phase: HeistPhase.rolePass,
        players: players,
        names: names,
        roleIndex: 0,
        leaderIndex: _random.nextInt(players.length),
        clearMessage: true,
      ),
    );
  }

  void revealRole() {
    if (state.phase != HeistPhase.rolePass) return;
    _audio.playReveal();
    emit(state.copyWith(phase: HeistPhase.roleReveal));
  }

  void hideRole() {
    if (state.phase != HeistPhase.roleReveal) return;
    if (state.roleIndex + 1 < state.players.length) {
      emit(
        state.copyWith(
          phase: HeistPhase.rolePass,
          roleIndex: state.roleIndex + 1,
        ),
      );
    } else {
      _prepareHeist(0);
    }
  }

  void _prepareHeist(int index) {
    _audio.playHeistMusic(tension: false);
    final bankSeed = state.sessionId.hashCode & 0x7fffffff;
    final bank =
        HeistCatalog.banks[(bankSeed + index) % HeistCatalog.banks.length];
    final events = List<HeistEvent>.of(HeistCatalog.events)..shuffle(_random);
    final selected = events.take(4).map((event) => event.id).toList();
    final players = [
      for (final player in state.players)
        player.copyWith(
          hiddenCash: 0,
          detected: false,
          abilityUsed: false,
          suspicion: max(0, player.suspicion - 1),
        ),
    ];
    emit(
      state.copyWith(
        phase: HeistPhase.planning,
        heistIndex: index,
        players: players,
        bankId: bank.id,
        clearPlan: true,
        clearEquipment: true,
        eventIds: selected,
        eventIndex: 0,
        operationScore: 0,
        alarm: 0,
        loot: 0,
        secretIndex: 0,
        decisions: const {},
        report: const [],
        proposal: const [],
        proposalAttempts: 0,
        votes: const [],
        voteIndex: 0,
        message: 'سرقت ${index + 1} از 3 • ${bank.title}',
      ),
    );
  }

  void choosePlan(HeistApproach plan) => emit(state.copyWith(plan: plan));
  void chooseEquipment(String equipment) =>
      emit(state.copyWith(equipment: equipment));

  void beginOperation() {
    if (state.phase != HeistPhase.planning ||
        state.plan == null ||
        state.equipment == null) {
      emit(state.copyWith(message: 'مسیر ورود و یک تجهیز را انتخاب کنید.'));
      return;
    }
    var score = 0;
    if (state.equipment == 'signal' && state.plan == HeistApproach.technology) {
      score += 2;
    }
    if (state.equipment == 'thermal' && state.plan == HeistApproach.force) {
      score += 2;
    }
    if (state.equipment == 'uniform' && state.plan == HeistApproach.social) {
      score += 2;
    }
    if (state.equipment == 'drone' && state.plan == HeistApproach.stealth) {
      score += 2;
    }
    if (state.equipment == 'emp' && currentBank.security >= 4) score++;
    _audio.playStart();
    _audio.playHeistMusic(tension: true);
    emit(
      state.copyWith(
        phase: HeistPhase.operation,
        operationScore: score,
        clearMessage: true,
      ),
    );
  }

  void resolveEvent(HeistApproach response) {
    if (state.phase != HeistPhase.operation) return;
    final event = currentEvent;
    final specialists = state.players
        .map(roleOf)
        .where((role) => role.specialty == response)
        .length;
    final correct = response == event.bestApproach;
    final empSaved =
        !correct &&
        state.equipment == 'emp' &&
        !state.report.any((line) => line.contains('پالس اضطراری'));
    final planSynergy = response == state.plan ? 1 : 0;
    final delta =
        (correct
                ? 2 + planSynergy + min(1, specialists)
                : empSaved
                ? 0
                : -event.danger)
            .toInt();
    final alarmPenalty = correct || empSaved
        ? 0
        : event.danger + state.difficulty.modifier;
    final alarm = state.alarm + alarmPenalty;
    final loot = state.loot + (correct ? event.reward : 0);
    final report = [
      ...state.report,
      correct
          ? '${event.title}: واکنش درست بود و ${event.reward} اعتبار غنیمت اضافه شد.'
          : empSaved
          ? '${event.title}: پالس اضطراری EMP فعال شد و جلوی افزایش هشدار را گرفت.'
          : '${event.title}: تصمیم اشتباه، سطح هشدار $alarmPenalty درجه بالا رفت.',
    ];
    _audio.play(
      correct
          ? GameSound.correct
          : empSaved
          ? GameSound.heistVault
          : GameSound.heistAlarm,
    );
    if (correct || empSaved) {
      _haptics.lightClick();
    } else {
      _haptics.mediumBump();
    }
    if (state.eventIndex + 1 < state.eventIds.length) {
      emit(
        state.copyWith(
          eventIndex: state.eventIndex + 1,
          operationScore: state.operationScore + delta,
          alarm: alarm,
          loot: loot,
          report: report,
        ),
      );
    } else {
      emit(
        state.copyWith(
          phase: HeistPhase.secretPass,
          secretIndex: 0,
          operationScore: state.operationScore + delta,
          alarm: alarm,
          loot: loot,
          report: report,
        ),
      );
    }
  }

  void openSecretChoice() {
    if (state.phase == HeistPhase.secretPass) {
      emit(state.copyWith(phase: HeistPhase.secretChoice));
    }
  }

  void chooseSecret(HeistSecretAction action) {
    if (state.phase != HeistPhase.secretChoice) return;
    if (action == HeistSecretAction.ability && secretPlayer.abilityUsed) {
      emit(
        state.copyWith(message: 'توانایی این نقش در این سرقت مصرف شده است.'),
      );
      return;
    }
    final decisions = Map<int, HeistSecretAction>.of(state.decisions)
      ..[state.secretIndex] = action;
    if (state.secretIndex + 1 < state.players.length) {
      emit(
        state.copyWith(
          phase: HeistPhase.secretPass,
          decisions: decisions,
          secretIndex: state.secretIndex + 1,
          clearMessage: true,
        ),
      );
    } else {
      _resolveSecrets(decisions);
    }
  }

  void _resolveSecrets(Map<int, HeistSecretAction> decisions) {
    final bank = currentBank;
    final target = operationTarget;
    final operationSucceeded =
        state.operationScore >= target && state.alarm <= alarmLimit;
    var loot = (operationSucceeded ? bank.baseLoot : bank.baseLoot * .35)
        .round();
    loot += state.loot;
    var score = state.operationScore;
    var alarm = state.alarm;
    final protectors = decisions.values
        .where((action) => action == HeistSecretAction.protect)
        .length;
    var players = List<HeistPlayer>.of(state.players);
    var detectedCount = 0;
    var betrayalCount = 0;

    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      final role = roleOf(player);
      final action = decisions[i] ?? HeistSecretAction.cooperate;
      switch (action) {
        case HeistSecretAction.cooperate:
          score++;
        case HeistSecretAction.protect:
          score++;
          players[i] = player.copyWith(cash: player.cash + 250);
        case HeistSecretAction.steal:
          betrayalCount++;
          final rawAmount = max(300, (loot * .08).round());
          final amount = state.equipment == 'decoy'
              ? (rawAmount * .5).round()
              : rawAmount;
          final detectionPressure =
              bank.security +
              player.suspicion +
              state.difficulty.modifier +
              protectors -
              (role.id == 'infiltrator' ? 2 : 0) +
              (role.id == 'security' ? 2 : 0);
          final detected = detectionPressure >= 5;
          if (detected) {
            detectedCount++;
            players[i] = player.copyWith(
              detected: true,
              suspicion: player.suspicion + 3,
            );
          } else {
            loot = max(0, loot - amount);
            players[i] = player.copyWith(
              hiddenCash: amount,
              suspicion: player.suspicion + 2,
            );
          }
        case HeistSecretAction.sabotage:
          betrayalCount++;
          final detected =
              bank.security + protectors + state.difficulty.modifier >= 5;
          final sabotageRate = state.equipment == 'decoy' ? .06 : .12;
          loot = max(0, loot - (loot * sabotageRate).round());
          alarm += 2;
          players[i] = player.copyWith(
            hiddenCash: detected ? 0 : 500,
            detected: detected,
            suspicion: player.suspicion + (detected ? 3 : 2),
          );
          if (detected) {
            detectedCount++;
          }
        case HeistSecretAction.ability:
          players[i] = player.copyWith(abilityUsed: true);
          if (role.id == 'driver') alarm = max(0, alarm - 2);
          if (role.id == 'safecracker') loot += (bank.baseLoot * .1).round();
          if (role.id == 'forger') {
            players[i] = players[i].copyWith(suspicion: 0);
          }
          if (role.id == 'mastermind') score += 2;
          if (role.id == 'hacker' || role.id == 'security') {
            alarm = max(0, alarm - 1);
          }
          if (role.id == 'infiltrator') {
            final amount = max(300, (bank.baseLoot * .06).round());
            loot = max(0, loot - amount);
            players[i] = players[i].copyWith(
              hiddenCash: amount,
              suspicion: player.suspicion + 1,
            );
          }
          if (role.id == 'negotiator') {
            players[i] = players[i].copyWith(cash: player.cash + 300);
          }
      }
      if (action == role.objectiveAction &&
          !(action == HeistSecretAction.steal && players[i].detected)) {
        players[i] = players[i].copyWith(cash: players[i].cash + 200);
      }
    }

    final finalSuccess = score >= target && alarm <= alarmLimit;
    if (!finalSuccess) loot = (loot * .65).round();
    final report = [
      ...state.report,
      finalSuccess
          ? 'گاوصندوق باز شد و گروه با غنیمت از محدوده خارج شد.'
          : 'عملیات نیمه‌موفق بود؛ بخشی از غنیمت هنگام فرار جا ماند.',
      '$betrayalCount حرکت مشکوک ثبت شد؛ $detectedCount مورد همان‌جا شناسایی شد.',
    ];
    _audio.play(
      betrayalCount > 0
          ? GameSound.heistBetrayal
          : finalSuccess
          ? GameSound.heistVault
          : GameSound.heistAlarm,
    );
    if (finalSuccess) {
      _haptics.mediumBump();
    } else {
      _haptics.buzzerFail();
    }
    emit(
      state.copyWith(
        phase: HeistPhase.operationReveal,
        players: players,
        decisions: decisions,
        operationScore: score,
        alarm: alarm,
        loot: max(0, loot),
        report: report,
        secretIndex: 0,
      ),
    );
  }

  void openAccusation() {
    if (state.phase == HeistPhase.operationReveal) {
      emit(state.copyWith(phase: HeistPhase.accusation));
    }
  }

  void accuse(int? targetIndex) {
    if (state.phase != HeistPhase.accusation) return;
    var players = List<HeistPlayer>.of(state.players);
    var loot = state.loot;
    String message;
    if (targetIndex == null) {
      message = 'گروه از اتهام رسمی صرف‌نظر کرد.';
    } else {
      final action = state.decisions[targetIndex];
      final guilty =
          action == HeistSecretAction.steal ||
          action == HeistSecretAction.sabotage;
      if (guilty) {
        final target = players[targetIndex];
        loot += target.hiddenCash;
        players[targetIndex] = target.copyWith(
          hiddenCash: 0,
          cash: max(0, target.cash - 400),
          detected: true,
          suspicion: target.suspicion + 2,
        );
        message = 'اتهام درست بود؛ پول مخفی ضبط و خائن جریمه شد.';
        _audio.playCorrect();
        _haptics.mediumBump();
      } else {
        final leader = players[state.leaderIndex];
        players[state.leaderIndex] = leader.copyWith(
          cash: max(0, leader.cash - 300),
        );
        message = 'اتهام اشتباه بود؛ رهبر 300 جریمه پرداخت کرد.';
        _audio.playBuzzer();
        _haptics.buzzerFail();
      }
    }
    emit(
      state.copyWith(
        phase: HeistPhase.division,
        players: players,
        loot: loot,
        proposal: _equalProposal(loot, players.length, state.leaderIndex),
        message: message,
      ),
    );
  }

  static List<int> _equalProposal(int loot, int count, int leader) {
    if (count == 0) return const [];
    final base = loot ~/ count;
    final proposal = List<int>.filled(count, base);
    proposal[leader] += loot - base * count;
    return proposal;
  }

  void shiftShare(int playerIndex, int delta) {
    if (state.phase != HeistPhase.division ||
        playerIndex == state.leaderIndex) {
      return;
    }
    final proposal = List<int>.of(state.proposal);
    final actual = delta > 0
        ? min(delta, proposal[state.leaderIndex])
        : -min(-delta, proposal[playerIndex]);
    proposal[playerIndex] += actual;
    proposal[state.leaderIndex] -= actual;
    emit(state.copyWith(proposal: proposal, clearMessage: true));
  }

  void resetEqualProposal() => emit(
    state.copyWith(
      proposal: _equalProposal(
        state.loot,
        state.players.length,
        state.leaderIndex,
      ),
    ),
  );

  void submitProposal() {
    if (state.phase != HeistPhase.division ||
        state.proposalTotal != state.loot) {
      return;
    }
    emit(
      state.copyWith(
        phase: HeistPhase.votePass,
        voteIndex: 0,
        votes: const [],
        clearMessage: true,
      ),
    );
  }

  void openVote() {
    if (state.phase == HeistPhase.votePass) {
      emit(state.copyWith(phase: HeistPhase.voteChoice));
    }
  }

  void castVote(bool approve) {
    if (state.phase != HeistPhase.voteChoice) return;
    final votes = [...state.votes, approve];
    if (state.voteIndex + 1 < state.players.length) {
      emit(
        state.copyWith(
          phase: HeistPhase.votePass,
          votes: votes,
          voteIndex: state.voteIndex + 1,
        ),
      );
      return;
    }
    final yes = votes.where((vote) => vote).length;
    final negotiatorIndex = state.players.indexWhere(
      (player) => player.roleId == 'negotiator',
    );
    final tiePasses =
        yes * 2 == votes.length &&
        negotiatorIndex >= 0 &&
        votes[negotiatorIndex];
    if (yes > votes.length / 2 || tiePasses) {
      _applyDistribution('پیشنهاد با $yes رأی موافق تصویب شد.');
      return;
    }
    if (state.proposalAttempts >= 1) {
      final emergency = _equalProposal(
        state.loot,
        state.players.length,
        state.leaderIndex,
      );
      emit(state.copyWith(proposal: emergency));
      _applyDistribution('دو پیشنهاد رد شد؛ تقسیم اضطراری برابر اجرا شد.');
      return;
    }
    final reducedLoot = (state.loot * .85).floor();
    final leader = (state.leaderIndex + 1) % state.players.length;
    emit(
      state.copyWith(
        phase: HeistPhase.division,
        loot: reducedLoot,
        leaderIndex: leader,
        proposal: _equalProposal(reducedLoot, state.players.length, leader),
        proposalAttempts: state.proposalAttempts + 1,
        votes: const [],
        voteIndex: 0,
        message: 'پیشنهاد رد شد؛ 15٪ غنیمت از دست رفت و رهبر عوض شد.',
      ),
    );
  }

  void _applyDistribution(String message) {
    final players = [
      for (var i = 0; i < state.players.length; i++)
        state.players[i].copyWith(
          cash:
              state.players[i].cash +
              state.proposal[i] +
              state.players[i].hiddenCash,
          hiddenCash: 0,
        ),
    ];
    _audio.play(GameSound.heistCash);
    emit(
      state.copyWith(
        phase: HeistPhase.heistSummary,
        players: players,
        message: message,
      ),
    );
  }

  void continueAfterSummary() {
    if (state.phase != HeistPhase.heistSummary) return;
    if (!state.isLastHeist) {
      final nextLeader = (state.leaderIndex + 1) % state.players.length;
      emit(state.copyWith(leaderIndex: nextLeader));
      _prepareHeist(state.heistIndex + 1);
      return;
    }
    final winner = rankedPlayers.first;
    _storage.recordGameResult(
      sessionId: state.sessionId,
      gameKey: 'heist',
      scores: {for (final player in state.players) player.name: player.cash},
      winnerName: winner.name,
    );
    _audio.stopMusic();
    _audio.playVictory();
    emit(state.copyWith(phase: HeistPhase.finalResult));
  }

  List<HeistPlayer> get rankedPlayers {
    final ranked = List<HeistPlayer>.of(state.players)
      ..sort((a, b) {
        final cash = b.cash.compareTo(a.cash);
        if (cash != 0) return cash;
        final suspicion = a.suspicion.compareTo(b.suspicion);
        if (suspicion != 0) return suspicion;
        return a.name.compareTo(b.name);
      });
    return ranked;
  }

  List<int> get rankedPositions =>
      denseRanks(rankedPlayers.map((player) => player.cash));

  void finishAndClear() => _storage.saveGameSession('heist', null);

  @override
  Future<void> close() {
    _audio.stopMusic();
    return super.close();
  }
}
