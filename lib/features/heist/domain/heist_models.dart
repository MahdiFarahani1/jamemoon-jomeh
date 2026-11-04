import 'package:equatable/equatable.dart';

enum HeistDifficulty { rookie, professional, legendary }

extension HeistDifficultyUi on HeistDifficulty {
  String get titleFa => switch (this) {
    HeistDifficulty.rookie => 'تازه‌کار',
    HeistDifficulty.professional => 'حرفه‌ای',
    HeistDifficulty.legendary => 'افسانه‌ای',
  };

  String get detailFa => switch (this) {
    HeistDifficulty.rookie =>
      'فرصت جبران بیشتر، سقف هشدار بالاتر و عملیات بخشنده‌تر.',
    HeistDifficulty.professional =>
      'تعادل اصلی بازی؛ اشتباه‌ها هزینه دارند و نقشه هماهنگ مهم است.',
    HeistDifficulty.legendary =>
      'هدف عملیات سخت‌تر و سقف هشدار پایین‌تر؛ هر تصمیم اشتباه خطرناک است.',
  };

  int get modifier => index;
}

enum HeistPhase {
  setup,
  rolePass,
  roleReveal,
  planning,
  operation,
  secretPass,
  secretChoice,
  operationReveal,
  accusation,
  division,
  votePass,
  voteChoice,
  heistSummary,
  finalResult,
}

enum HeistApproach { stealth, technology, force, social }

extension HeistApproachUi on HeistApproach {
  String get titleFa => switch (this) {
    HeistApproach.stealth => 'نفوذ بی‌صدا',
    HeistApproach.technology => 'حمله سایبری',
    HeistApproach.force => 'ورود فنی',
    HeistApproach.social => 'مهندسی اجتماعی',
  };
}

enum HeistSecretAction { cooperate, steal, sabotage, protect, ability }

extension HeistSecretActionUi on HeistSecretAction {
  String get titleFa => switch (this) {
    HeistSecretAction.cooperate => 'همکاری کامل',
    HeistSecretAction.steal => 'برداشت مخفیانه',
    HeistSecretAction.sabotage => 'خرابکاری',
    HeistSecretAction.protect => 'محافظت از غنیمت',
    HeistSecretAction.ability => 'توانایی نقش',
  };

  String get detailFa => switch (this) {
    HeistSecretAction.cooperate => 'ریسک صفر؛ شانس موفقیت گروه بیشتر می‌شود.',
    HeistSecretAction.steal =>
      'پول شخصی بیشتر، اما احتمال شناسایی و جریمه دارد.',
    HeistSecretAction.sabotage =>
      'غنیمت گروه کم می‌شود؛ در صورت لو رفتن جریمه سنگین است.',
    HeistSecretAction.protect =>
      'احتمال کشف خیانت بالا می‌رود و پاداش محافظ می‌گیری.',
    HeistSecretAction.ability =>
      'اثر اختصاصی نقش را یک‌بار در این سرقت فعال می‌کند.',
  };
}

class HeistRole extends Equatable {
  const HeistRole({
    required this.id,
    required this.title,
    required this.ability,
    required this.strength,
    required this.weakness,
    required this.objective,
    required this.objectiveAction,
    required this.specialty,
    required this.atlasIndex,
  });

  final String id;
  final String title;
  final String ability;
  final String strength;
  final String weakness;
  final String objective;
  final HeistSecretAction objectiveAction;
  final HeistApproach specialty;
  final int atlasIndex;

  Map<String, dynamic> toJson() => {'id': id};

  @override
  List<Object?> get props => [id];
}

class HeistBank extends Equatable {
  const HeistBank({
    required this.id,
    required this.title,
    required this.security,
    required this.baseLoot,
    required this.description,
    required this.atlasIndex,
  });

  final String id;
  final String title;
  final int security;
  final int baseLoot;
  final String description;
  final int atlasIndex;

  @override
  List<Object?> get props => [id];
}

class HeistEvent extends Equatable {
  const HeistEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.bestApproach,
    required this.danger,
    required this.reward,
    required this.artIndex,
  });

  final String id;
  final String title;
  final String description;
  final HeistApproach bestApproach;
  final int danger;
  final int reward;
  final int artIndex;

  @override
  List<Object?> get props => [id];
}

class HeistPlayer extends Equatable {
  const HeistPlayer({
    required this.id,
    required this.name,
    required this.roleId,
    this.cash = 0,
    this.suspicion = 0,
    this.hiddenCash = 0,
    this.detected = false,
    this.abilityUsed = false,
  });

  final String id;
  final String name;
  final String roleId;
  final int cash;
  final int suspicion;
  final int hiddenCash;
  final bool detected;
  final bool abilityUsed;

  HeistPlayer copyWith({
    int? cash,
    int? suspicion,
    int? hiddenCash,
    bool? detected,
    bool? abilityUsed,
  }) => HeistPlayer(
    id: id,
    name: name,
    roleId: roleId,
    cash: (cash ?? this.cash).clamp(0, 999999999),
    suspicion: (suspicion ?? this.suspicion).clamp(0, 10),
    hiddenCash: (hiddenCash ?? this.hiddenCash).clamp(0, 999999999),
    detected: detected ?? this.detected,
    abilityUsed: abilityUsed ?? this.abilityUsed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'roleId': roleId,
    'cash': cash,
    'suspicion': suspicion,
    'hiddenCash': hiddenCash,
    'detected': detected,
    'abilityUsed': abilityUsed,
  };

  factory HeistPlayer.fromJson(Map<String, dynamic> json) => HeistPlayer(
    id: json['id'] as String,
    name: json['name'] as String,
    roleId: json['roleId'] as String,
    cash: json['cash'] as int,
    suspicion: json['suspicion'] as int,
    hiddenCash: json['hiddenCash'] as int,
    detected: json['detected'] as bool,
    abilityUsed: json['abilityUsed'] as bool,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    roleId,
    cash,
    suspicion,
    hiddenCash,
    detected,
    abilityUsed,
  ];
}

class HeistState extends Equatable {
  const HeistState({
    this.phase = HeistPhase.setup,
    this.names = const ['بازیکن 1', 'بازیکن 2', 'بازیکن 3', 'بازیکن 4'],
    this.difficulty = HeistDifficulty.professional,
    this.players = const [],
    this.roleIndex = 0,
    this.heistIndex = 0,
    this.leaderIndex = 0,
    this.bankId,
    this.plan,
    this.equipment,
    this.eventIds = const [],
    this.eventIndex = 0,
    this.operationScore = 0,
    this.alarm = 0,
    this.loot = 0,
    this.secretIndex = 0,
    this.decisions = const {},
    this.report = const [],
    this.proposal = const [],
    this.proposalAttempts = 0,
    this.voteIndex = 0,
    this.votes = const [],
    this.message,
    this.sessionId = '',
  });

  final HeistPhase phase;
  final List<String> names;
  final HeistDifficulty difficulty;
  final List<HeistPlayer> players;
  final int roleIndex;
  final int heistIndex;
  final int leaderIndex;
  final String? bankId;
  final HeistApproach? plan;
  final String? equipment;
  final List<String> eventIds;
  final int eventIndex;
  final int operationScore;
  final int alarm;
  final int loot;
  final int secretIndex;
  final Map<int, HeistSecretAction> decisions;
  final List<String> report;
  final List<int> proposal;
  final int proposalAttempts;
  final int voteIndex;
  final List<bool> votes;
  final String? message;
  final String sessionId;

  bool get isLastHeist => heistIndex >= 2;
  int get proposalTotal => proposal.fold(0, (sum, value) => sum + value);
  int get proposalRemaining => loot - proposalTotal;

  HeistState copyWith({
    HeistPhase? phase,
    List<String>? names,
    HeistDifficulty? difficulty,
    List<HeistPlayer>? players,
    int? roleIndex,
    int? heistIndex,
    int? leaderIndex,
    String? bankId,
    bool clearBank = false,
    HeistApproach? plan,
    bool clearPlan = false,
    String? equipment,
    bool clearEquipment = false,
    List<String>? eventIds,
    int? eventIndex,
    int? operationScore,
    int? alarm,
    int? loot,
    int? secretIndex,
    Map<int, HeistSecretAction>? decisions,
    List<String>? report,
    List<int>? proposal,
    int? proposalAttempts,
    int? voteIndex,
    List<bool>? votes,
    String? message,
    bool clearMessage = false,
    String? sessionId,
  }) => HeistState(
    phase: phase ?? this.phase,
    names: List.unmodifiable(names ?? this.names),
    difficulty: difficulty ?? this.difficulty,
    players: List.unmodifiable(players ?? this.players),
    roleIndex: roleIndex ?? this.roleIndex,
    heistIndex: heistIndex ?? this.heistIndex,
    leaderIndex: leaderIndex ?? this.leaderIndex,
    bankId: clearBank ? null : bankId ?? this.bankId,
    plan: clearPlan ? null : plan ?? this.plan,
    equipment: clearEquipment ? null : equipment ?? this.equipment,
    eventIds: List.unmodifiable(eventIds ?? this.eventIds),
    eventIndex: eventIndex ?? this.eventIndex,
    operationScore: operationScore ?? this.operationScore,
    alarm: alarm ?? this.alarm,
    loot: loot ?? this.loot,
    secretIndex: secretIndex ?? this.secretIndex,
    decisions: Map.unmodifiable(decisions ?? this.decisions),
    report: List.unmodifiable(report ?? this.report),
    proposal: List.unmodifiable(proposal ?? this.proposal),
    proposalAttempts: proposalAttempts ?? this.proposalAttempts,
    voteIndex: voteIndex ?? this.voteIndex,
    votes: List.unmodifiable(votes ?? this.votes),
    message: clearMessage ? null : message ?? this.message,
    sessionId: sessionId ?? this.sessionId,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'phase': phase.name,
    'names': names,
    'difficulty': difficulty.name,
    'players': players.map((player) => player.toJson()).toList(),
    'roleIndex': roleIndex,
    'heistIndex': heistIndex,
    'leaderIndex': leaderIndex,
    'bankId': bankId,
    'plan': plan?.name,
    'equipment': equipment,
    'eventIds': eventIds,
    'eventIndex': eventIndex,
    'operationScore': operationScore,
    'alarm': alarm,
    'loot': loot,
    'secretIndex': secretIndex,
    'decisions': decisions.map((key, value) => MapEntry('$key', value.name)),
    'report': report,
    'proposal': proposal,
    'proposalAttempts': proposalAttempts,
    'voteIndex': voteIndex,
    'votes': votes,
    'message': message,
    'sessionId': sessionId,
  };

  factory HeistState.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('heist version');
    return HeistState(
      phase: HeistPhase.values.byName(json['phase'] as String),
      names: (json['names'] as List).cast<String>(),
      difficulty: HeistDifficulty.values.byName(json['difficulty'] as String),
      players: (json['players'] as List)
          .map(
            (row) =>
                HeistPlayer.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      roleIndex: json['roleIndex'] as int,
      heistIndex: json['heistIndex'] as int,
      leaderIndex: json['leaderIndex'] as int,
      bankId: json['bankId'] as String?,
      plan: json['plan'] == null
          ? null
          : HeistApproach.values.byName(json['plan'] as String),
      equipment: json['equipment'] as String?,
      eventIds: (json['eventIds'] as List).cast<String>(),
      eventIndex: json['eventIndex'] as int,
      operationScore: json['operationScore'] as int,
      alarm: json['alarm'] as int,
      loot: json['loot'] as int,
      secretIndex: json['secretIndex'] as int,
      decisions: (json['decisions'] as Map).map(
        (key, value) => MapEntry(
          int.parse(key.toString()),
          HeistSecretAction.values.byName(value as String),
        ),
      ),
      report: (json['report'] as List).cast<String>(),
      proposal: (json['proposal'] as List).cast<int>(),
      proposalAttempts: json['proposalAttempts'] as int,
      voteIndex: json['voteIndex'] as int,
      votes: (json['votes'] as List).cast<bool>(),
      message: json['message'] as String?,
      sessionId: json['sessionId'] as String,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    names,
    difficulty,
    players,
    roleIndex,
    heistIndex,
    leaderIndex,
    bankId,
    plan,
    equipment,
    eventIds,
    eventIndex,
    operationScore,
    alarm,
    loot,
    secretIndex,
    decisions,
    report,
    proposal,
    proposalAttempts,
    voteIndex,
    votes,
    message,
    sessionId,
  ];
}
