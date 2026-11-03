import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/models/team_model.dart';
import '../presentation/cubit/decoder_state.dart';

String normalizeDecoderWord(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll('ي', 'ی')
    .replaceAll('ى', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp(r'[\s\u200c\u200d]+'), '');

bool isDecoderWord(String input) =>
    RegExp(r'^[a-z\u0621-\u063a\u0641-\u064a\u0671-\u06d3]+$')
        .hasMatch(normalizeDecoderWord(input)) &&
    !RegExp(r'\s').hasMatch(input);

class DecoderRepository {
  final StorageService storageService;
  final Random random;
  final AssetBundle bundle;
  DecoderRepository({
    required this.storageService,
    Random? random,
    AssetBundle? bundle,
  }) : random = random ?? Random(),
       bundle = bundle ?? rootBundle;

  Future<List<String>> loadWords() async {
    final decoded = jsonDecode(
      await bundle.loadString('assets/data/decoder/pack_free.json'),
    ) as List;
    final unique = <String, String>{};
    for (final value in [
      ...decoded,
      ...storageService.getCustomCards().map((c) => c['word']),
    ]) {
      if (value is! String) continue;
      final word = value.trim();
      if (word.isEmpty || word.length > 24 || RegExp(r'\s').hasMatch(word)) {
        continue;
      }
      final key = normalizeDecoderWord(word);
      if (isDecoderWord(word)) unique.putIfAbsent(key, () => word);
    }
    if (unique.length < 25) {
      throw const FormatException('Insufficient decoder words');
    }
    return unique.values.toList();
  }

  Future<DecoderState> newGame(Team first, Team second) async {
    if (first.id == second.id) throw ArgumentError('Teams must be different');
    final words = await loadWords();
    words.shuffle(random);
    final starter = random.nextInt(2);
    final roles = <DecoderRole>[
      ...List.filled(starter == 0 ? 9 : 8, DecoderRole.team0),
      ...List.filled(starter == 1 ? 9 : 8, DecoderRole.team1),
      ...List.filled(7, DecoderRole.neutral),
      DecoderRole.hazard,
    ]..shuffle(random);
    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32)}';
    return DecoderState(
      phase: DecoderPhase.shield,
      shieldTarget: DecoderPhase.guide,
      sessionId: id,
      teams: [first, second],
      activeTeam: starter,
      startingTeam: starter,
      cards: List.generate(25, (i) => DecoderCard(words[i], roles[i])),
    );
  }

  DecoderState? restore() {
    try {
      final json = storageService.getActiveDecoder();
      if (json == null || json['version'] != 1) return null;
      final id = json['sessionId'] as String;
      final teams = (json['teams'] as List)
          .map((e) => Team.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final cards = (json['cards'] as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return DecoderCard(
          m['word'] as String,
          DecoderRole.values.byName(m['role'] as String),
          revealed: m['revealed'] as bool,
        );
      }).toList();
      final active = json['activeTeam'] as int;
      final starter = json['startingTeam'] as int;
      final clue = json['clue'] as String;
      final count = json['clueCount'] as int;
      final left = json['guessesLeft'] as int;
      final winner = json['winner'] as int?;
      final phase = DecoderPhase.values.byName(json['phase'] as String);
      final target = DecoderPhase.values.byName(json['shieldTarget'] as String);
      final wordKeys = cards.map((c) => normalizeDecoderWord(c.word)).toSet();
      if (id.isEmpty ||
          teams.length != 2 ||
          teams[0].id == teams[1].id ||
          teams.any((t) => t.id.isEmpty || t.name.trim().isEmpty) ||
          cards.length != 25 ||
          wordKeys.length != 25 ||
          wordKeys.contains('') ||
          active < 0 ||
          active > 1 ||
          starter < 0 ||
          starter > 1 ||
          count < 0 ||
          left < 0 ||
          left > count + 1 ||
          (winner != null && (winner < 0 || winner > 1)) ||
          phase == DecoderPhase.setup ||
          target == DecoderPhase.setup ||
          target == DecoderPhase.shield ||
          cards.where((c) => c.role == DecoderRole.team0).length !=
              (starter == 0 ? 9 : 8) ||
          cards.where((c) => c.role == DecoderRole.team1).length !=
              (starter == 1 ? 9 : 8) ||
          cards.where((c) => c.role == DecoderRole.neutral).length != 7 ||
          cards.where((c) => c.role == DecoderRole.hazard).length != 1) {
        return null;
      }
      final hazardRevealed = cards.any(
        (c) => c.role == DecoderRole.hazard && c.revealed,
      );
      final team0Complete = cards
          .where((c) => c.role == DecoderRole.team0)
          .every((c) => c.revealed);
      final team1Complete = cards
          .where((c) => c.role == DecoderRole.team1)
          .every((c) => c.revealed);
      final resume = phase == DecoderPhase.shield ? target : phase;
      if ((resume == DecoderPhase.result) != (winner != null) ||
          (resume == DecoderPhase.guessing &&
              (clue.isEmpty || count < 1 || left < 1))) {
        return null;
      }
      if (resume != DecoderPhase.result &&
          (hazardRevealed || team0Complete || team1Complete)) {
        return null;
      }
      if (resume == DecoderPhase.result &&
          !(hazardRevealed && winner == 1 - active ||
              !hazardRevealed &&
                  ((winner == 0 && team0Complete) ||
                      (winner == 1 && team1Complete)))) {
        return null;
      }
      if (resume == DecoderPhase.guessing &&
          (!isDecoderWord(clue) ||
              cards.any(
                (c) =>
                    normalizeDecoderWord(c.word) == normalizeDecoderWord(clue),
              ))) {
        return null;
      }
      return DecoderState(
        phase: DecoderPhase.shield,
        shieldTarget: resume,
        sessionId: id,
        teams: teams,
        cards: cards,
        activeTeam: active,
        startingTeam: starter,
        clue: clue,
        clueCount: count,
        guessesLeft: left,
        winner: winner,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DecoderState? state) =>
      storageService.saveActiveDecoder(state?.toJson());
  Future<void> recordResult(DecoderState state) {
    final sameName = state.teams[0].name == state.teams[1].name;
    String label(int index) => sameName
        ? '${state.teams[index].name} (${index + 1})'
        : state.teams[index].name;
    return storageService.recordGameResult(
      sessionId: state.sessionId,
      gameKey: 'decoder',
      scores: {
        for (var i = 0; i < 2; i++)
          label(i): state.cards
              .where(
                (c) =>
                    c.revealed &&
                    c.role == (i == 0 ? DecoderRole.team0 : DecoderRole.team1),
              )
              .length,
      },
      winnerName: label(state.winner!),
    );
  }
}
