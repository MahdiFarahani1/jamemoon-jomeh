import 'package:equatable/equatable.dart';

import '../../../../core/models/team_model.dart';

enum DecoderRole { team0, team1, neutral, hazard }

enum DecoderPhase { setup, shield, guide, guessing, reveal, result }

class DecoderCard extends Equatable {
  final String word;
  final DecoderRole role;
  final bool revealed;
  const DecoderCard(this.word, this.role, {this.revealed = false});
  DecoderCard reveal() => DecoderCard(word, role, revealed: true);
  Map<String, dynamic> toJson() => {
    'word': word,
    'role': role.name,
    'revealed': revealed,
  };
  @override
  List<Object?> get props => [word, role, revealed];
}

class DecoderState extends Equatable {
  final DecoderPhase phase;
  final DecoderPhase shieldTarget;
  final List<Team> teams;
  final List<DecoderCard> cards;
  final String sessionId;
  final int activeTeam;
  final int startingTeam;
  final String clue;
  final int clueCount;
  final int guessesLeft;
  final int? winner;
  final bool mapVisible;
  final String? error;
  final String? rosterError;
  final String? selectedFirst;
  final String? selectedSecond;

  DecoderState({
    this.phase = DecoderPhase.setup,
    this.shieldTarget = DecoderPhase.guide,
    List<Team> teams = const [],
    List<DecoderCard> cards = const [],
    this.sessionId = '',
    this.activeTeam = 0,
    this.startingTeam = 0,
    this.clue = '',
    this.clueCount = 0,
    this.guessesLeft = 0,
    this.winner,
    this.mapVisible = false,
    this.error,
    this.rosterError,
    this.selectedFirst,
    this.selectedSecond,
  }) : teams = List.unmodifiable(teams),
       cards = List.unmodifiable(cards);

  DecoderState copyWith({
    DecoderPhase? phase,
    DecoderPhase? shieldTarget,
    List<Team>? teams,
    List<DecoderCard>? cards,
    String? sessionId,
    int? activeTeam,
    int? startingTeam,
    String? clue,
    int? clueCount,
    int? guessesLeft,
    int? winner,
    bool clearWinner = false,
    bool? mapVisible,
    String? error,
    bool clearError = false,
    String? rosterError,
    bool clearRosterError = false,
    String? selectedFirst,
    String? selectedSecond,
  }) => DecoderState(
    phase: phase ?? this.phase,
    shieldTarget: shieldTarget ?? this.shieldTarget,
    teams: teams ?? this.teams,
    cards: cards ?? this.cards,
    sessionId: sessionId ?? this.sessionId,
    activeTeam: activeTeam ?? this.activeTeam,
    startingTeam: startingTeam ?? this.startingTeam,
    clue: clue ?? this.clue,
    clueCount: clueCount ?? this.clueCount,
    guessesLeft: guessesLeft ?? this.guessesLeft,
    winner: clearWinner ? null : winner ?? this.winner,
    mapVisible: mapVisible ?? this.mapVisible,
    error: clearError ? null : error ?? this.error,
    rosterError: clearRosterError ? null : rosterError ?? this.rosterError,
    selectedFirst: selectedFirst ?? this.selectedFirst,
    selectedSecond: selectedSecond ?? this.selectedSecond,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'sessionId': sessionId,
    'phase': phase.name,
    'shieldTarget': shieldTarget.name,
    'teams': teams.map((t) => t.toJson()).toList(),
    'cards': cards.map((c) => c.toJson()).toList(),
    'activeTeam': activeTeam,
    'startingTeam': startingTeam,
    'clue': clue,
    'clueCount': clueCount,
    'guessesLeft': guessesLeft,
    'winner': winner,
  };

  @override
  List<Object?> get props => [
    phase,
    shieldTarget,
    teams,
    cards,
    sessionId,
    activeTeam,
    startingTeam,
    clue,
    clueCount,
    guessesLeft,
    winner,
    mapVisible,
    error,
    rosterError,
    selectedFirst,
    selectedSecond,
  ];
}
