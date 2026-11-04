import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/game_result.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/game_setup_config.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_card.dart';
import '../../../../core/widgets/party_dialog.dart';
import '../../../../core/widgets/game_emblem.dart';
import '../../../../core/widgets/game_lifecycle_guard.dart';
import '../../../../core/widgets/game_scene.dart';
import '../../../../core/widgets/how_to_play_sheet.dart';
import '../../../../core/widgets/member_name_dialog.dart';
import '../../../../core/widgets/team_identity.dart';
import '../../../teams/presentation/cubit/teams_cubit.dart';
import '../../data/decoder_repository.dart';
import '../cubit/decoder_cubit.dart';
import '../cubit/decoder_state.dart';

class DecoderGamePage extends StatelessWidget {
  final bool autoStart;
  final bool resumeSaved;
  const DecoderGamePage({
    super.key,
    this.autoStart = false,
    this.resumeSaved = false,
  });
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DecoderCubit(
      repository: sl<DecoderRepository>(),
      resumeSaved: resumeSaved,
    ),
    child: _DecoderView(autoStart: autoStart),
  );
}

class _DecoderView extends StatefulWidget {
  final bool autoStart;
  const _DecoderView({this.autoStart = false});
  @override
  State<_DecoderView> createState() => _DecoderViewState();
}

class _DecoderViewState extends State<_DecoderView>
    with WidgetsBindingObserver {
  final _clue = TextEditingController();
  final _number = TextEditingController();
  late DecoderCubit _cubit;
  Animation<double>? _secondaryAnimation;
  bool _confirmingExit = false;

  Future<void> _confirmExit() async {
    if (_confirmingExit) return;
    _confirmingExit = true;
    _cubit.shield();
    try {
      final confirmed = await PartyDialog.show(
        context,
        title: 'خروج از رمزگشا',
        message: 'می‌خواهید از بازی خارج شوید؟ بازی ذخیره می‌شود و می‌توانید بعداً ادامه دهید.',
        confirmLabel: 'خروج',
        cancelLabel: 'ادامه بازی',
      );
      if (confirmed == true && mounted) Navigator.of(context).pop();
    } finally {
      _confirmingExit = false;
    }
  }

  Future<void> _addMember(String teamId) async {
    final name = await MemberNameDialog.show(context);
    if (!mounted || name == null) return;
    if (name.isEmpty) {
      _cubit.showRosterError('نام بازیکن را وارد کنید.');
      return;
    }
    context.read<TeamsCubit>().addPlayer(name: name, teamId: teamId);
    _cubit.clearRosterError();
  }

  Future<void> _editTeam(Team team) async {
    final cubit = context.read<TeamsCubit>();
    final appearance = await TeamAppearanceSheet.show(context, team);
    if (!mounted || appearance == null) return;
    cubit.updateTeam(
      team.id,
      name: appearance.$1,
      colorValue: appearance.$2,
      iconKey: appearance.$3,
    );
  }

  @override
  void initState() {
    super.initState();
    _cubit = context.read<DecoderCubit>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_cubit.state.phase == DecoderPhase.setup) {
        final teams = context.read<TeamsCubit>().state.teams;
        if (teams.length >= 2 && teams[0].id != teams[1].id) {
          _cubit.startGame(teams[0], teams[1]);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.secondaryAnimation;
    if (_secondaryAnimation != animation) {
      _secondaryAnimation?.removeListener(_onSecondaryAnimation);
      _secondaryAnimation = animation;
      _secondaryAnimation?.addListener(_onSecondaryAnimation);
    }
    if (ModalRoute.of(context)?.isCurrent == false) {
      scheduleShield();
    }
  }

  void _onSecondaryAnimation() {
    if (ModalRoute.of(context)?.isCurrent == false) {
      _cubit.shield();
    }
  }

  void scheduleShield() {
    scheduleMicrotask(() {
      if (mounted) _cubit.shield();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cubit.shield();
    }
  }

  @override
  void dispose() {
    _secondaryAnimation?.removeListener(_onSecondaryAnimation);
    WidgetsBinding.instance.removeObserver(this);
    _cubit.shield();
    _clue.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<DecoderCubit, DecoderState>(
    builder: (context, state) => PopScope(
      canPop:
          state.phase == DecoderPhase.setup ||
          state.phase == DecoderPhase.result,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رمزگشا'),
          actions: [
            IconButton(
              tooltip: 'آموزش بازی',
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => HowToPlaySheet.show(context, 'decoder'),
            ),
          ],
          bottom: const GameSceneRibbon(gameKey: 'decoder'),
        ),
        body: AnimatedPartyBackground(
          gameKey: 'decoder',
          child: SafeArea(
            child: switch (state.phase) {
              DecoderPhase.setup => _setup(context, state),
              DecoderPhase.shield => _shield(context, state),
              DecoderPhase.guide => _guide(context, state),
              DecoderPhase.guessing => _guessing(context, state),
              DecoderPhase.reveal => _reveal(context, state),
              DecoderPhase.result => _result(context, state),
            },
          ),
        ),
      ),
    ),
  );

  Widget _setup(BuildContext context, DecoderState state) {
    final teams = context.watch<TeamsCubit>().state.teams;
    Team? find(String? id) {
      for (final team in teams) {
        if (team.id == id) return team;
      }
      return null;
    }

    final first = find(state.selectedFirst);
    final second = find(state.selectedSecond);
    Widget selection(int slot, Team? selected) =>
        DropdownButtonFormField<String>(
          initialValue: selected?.id,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: slot == 0 ? 'تیم اول' : 'تیم دوم',
            border: const OutlineInputBorder(),
          ),
          items: teams
              .map(
                (team) =>
                    DropdownMenuItem(value: team.id, child: Text(team.name)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _cubit.clearRosterError();
              _cubit.selectTeam(slot, value);
            }
          },
        );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        const GameEmblem(gameKey: 'decoder', size: 100),
        const SizedBox(height: 12),
        const Text(
          'راز کلمه‌ها را کشف کنید',
          textAlign: TextAlign.center,
          style: AppTypography.displayMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'دو تیم انتخاب کنید. راهنما نقشه مخفی را می‌بیند و با یک سرنخ، تیمش را به کلمه‌ها می‌رساند.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
        const SizedBox(height: 24),
        PartyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('انتخاب تیم‌ها', style: AppTypography.headlineLarge),
              const SizedBox(height: 16),
              selection(0, first),
              const SizedBox(height: 14),
              selection(1, second),
              if (first != null || second != null) ...[
                const SizedBox(height: 16),
                const Text('اعضای تیم‌ها *', style: AppTypography.titleLarge),
                const Text('هر تیم دست‌کم دو عضو لازم دارد.'),
                for (final team in [first, second].whereType<Team>()) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TeamAvatar(team: team, size: 38),
                      const SizedBox(width: 8),
                      Expanded(child: Text(team.name)),
                      IconButton(
                        tooltip: 'ویرایش تیم',
                        onPressed: () => _editTeam(team),
                        icon: const Icon(Icons.palette_outlined),
                      ),
                      TextButton.icon(
                        onPressed: () => _addMember(team.id),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('عضو'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final player
                          in context.watch<TeamsCubit>().state.players.where(
                            (p) => p.teamId == team.id,
                          ))
                        InputChip(
                          label: Text(player.name),
                          onDeleted: () => context
                              .read<TeamsCubit>()
                              .removePlayer(player.id),
                        ),
                    ],
                  ),
                ],
              ],
              if (first != null && second != null && first.id == second.id)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'دو تیم متفاوت انتخاب کنید.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              if (state.rosterError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.rosterError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: 18),
              PartyButton(
                label: 'ساخت صفحه رمز',
                icon: Icons.auto_awesome,
                color: AppColors.accent,
                onPressed:
                    first != null && second != null && first.id != second.id
                    ? () {
                        final error = GameSetupRequirements.validate(
                          'decoder',
                          [first, second],
                          context.read<TeamsCubit>().state.players,
                        );
                        if (error != null) {
                          _cubit.showRosterError(error);
                          return;
                        }
                        _cubit.clearRosterError();
                        _cubit.startGame(first, second);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'هر تیم یک راهنما دارد. کارت خطر بازی را فوراً به نفع حریف تمام می‌کند.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _shield(BuildContext context, DecoderState state) {
    final target = state.shieldTarget;
    final title = target == DecoderPhase.guide
        ? 'گوشی را به راهنما بدهید'
        : target == DecoderPhase.guessing
        ? 'گوشی را به حدس‌زن‌ها بدهید'
        : 'آماده دیدن نتیجه‌اید؟';
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          const GameEmblem(gameKey: 'decoder', size: 120),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            state.teams[state.activeTeam].name,
            textAlign: TextAlign.center,
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'پیش از ادامه مطمئن شوید فقط افراد مناسب صفحه را می‌بینند.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: 28),
          PartyButton(
            label: 'آماده‌ام',
            icon: Icons.lock_open_rounded,
            color: AppColors.success,
            onPressed: _cubit.dismissShield,
          ),
        ],
      ),
    );
  }

  Widget _guide(BuildContext context, DecoderState state) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _heading(state, 'نوبت راهنما'),
      const SizedBox(height: 12),
      PartyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.mapVisible ? 'نقشه فقط برای راهنما' : 'نقشه مخفی است',
              style: AppTypography.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.mapVisible
                  ? 'پس از بررسی، نقشه را ببندید.'
                  : 'مطمئن شوید بازیکنان دیگر صفحه را نمی‌بینند.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            PartyButton(
              label: state.mapVisible ? 'بستن نقشه' : 'نمایش آگاهانه نقشه',
              icon: state.mapVisible ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF6750A4),
              onPressed: state.mapVisible ? _cubit.hideMap : _cubit.showMap,
            ),
          ],
        ),
      ),
      if (state.mapVisible) ...[
        const SizedBox(height: 12),
        _legend(state),
        const SizedBox(height: 10),
        _board(context, state, map: true),
      ],
      if (!state.mapVisible) ...[
        const SizedBox(height: 14),
        PartyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('سرنخ راهنما', style: AppTypography.headlineMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _clue,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'یک کلمه سرنخ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'تعداد کلمه‌ها',
                  border: OutlineInputBorder(),
                ),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: 16),
              PartyButton(
                label: 'ثبت سرنخ و تحویل گوشی',
                color: const Color(0xFF168A86),
                onPressed: () {
                  _cubit.submitClue(_clue.text, _number.text);
                  if (_cubit.state.phase == DecoderPhase.shield) {
                    _clue.clear();
                    _number.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
    ],
  );

  Widget _guessing(BuildContext context, DecoderState state) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _heading(state, 'نوبت حدس'),
      const SizedBox(height: 12),
      PartyCard(
        child: Column(
          children: [
            Text(
              'سرنخ: ${state.clue}  •  ${state.clueCount}',
              style: AppTypography.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              '${state.guessesLeft} حدس باقی مانده',
              style: AppTypography.bodyLarge,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _board(context, state),
      const SizedBox(height: 16),
      PartyButton(
        label: 'پایان نوبت',
        color: const Color(0xFF6750A4),
        onPressed: _cubit.endTurn,
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget _reveal(BuildContext context, DecoderState state) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'نوبت پایان یافت',
        style: AppTypography.headlineLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      _board(context, state, readOnly: true),
      const SizedBox(height: 16),
      PartyButton(
        label: 'نوبت تیم بعدی',
        color: const Color(0xFF168A86),
        onPressed: _cubit.continueTurn,
      ),
      const SizedBox(height: 20),
    ],
  );
  Widget _heading(DecoderState state, String subtitle) => Row(
    children: [
      const Icon(Icons.key_rounded, color: Color(0xFFE4B55E), size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.teams[state.activeTeam].name,
              style: AppTypography.headlineLarge,
            ),
            Text(subtitle, style: AppTypography.bodyMedium),
          ],
        ),
      ),
      for (var i = 0; i < 2; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Chip(
            label: Text(
              '${state.cards.where((c) => !c.revealed && c.role == (i == 0 ? DecoderRole.team0 : DecoderRole.team1)).length}',
            ),
            backgroundColor: i == 0
                ? const Color(0xFF6750A4)
                : const Color(0xFF168A86),
          ),
        ),
    ],
  );

  Widget _legend(DecoderState state) => Wrap(
    spacing: 10,
    runSpacing: 6,
    children: [
      _legendItem(state.teams[0].name, const Color(0xFF6750A4)),
      _legendItem(state.teams[1].name, const Color(0xFF168A86)),
      _legendItem('خنثی', const Color(0xFF927C5B)),
      _legendItem('خطر', const Color(0xFFB63E54)),
    ],
  );
  Widget _legendItem(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: AppTypography.bodySmall),
    ],
  );

  Widget _board(
    BuildContext context,
    DecoderState state, {
    bool map = false,
    bool readOnly = false,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final width = math.max(
      MediaQuery.sizeOf(context).width - 32,
      280.0 * scale,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 25,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final card = state.cards[index];
            final visible = map || card.revealed;
            final color = !visible
                ? const Color(0xFF293047)
                : switch (card.role) {
                    DecoderRole.team0 => const Color(0xFF6750A4),
                    DecoderRole.team1 => const Color(0xFF168A86),
                    DecoderRole.neutral => const Color(0xFF927C5B),
                    DecoderRole.hazard => const Color(0xFFB63E54),
                  };
            final role = switch (card.role) {
              DecoderRole.team0 => state.teams[0].name,
              DecoderRole.team1 => state.teams[1].name,
              DecoderRole.neutral => 'خنثی',
              DecoderRole.hazard => 'خطر',
            };
            return Semantics(
              button: !map && !readOnly && !card.revealed,
              onTap: !map && !readOnly && !card.revealed
                  ? () => _cubit.guess(index)
                  : null,
              label: visible
                  ? '${card.word}، $role${card.revealed ? '، آشکار شده' : ''}'
                  : card.word,
              child: ExcludeSemantics(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: !map && !readOnly && !card.revealed
                        ? () => _cubit.guess(index)
                        : null,
                    child: _FlipCard(
                      revealed: card.revealed && !map,
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: visible
                                ? Colors.white38
                                : const Color(0xFF796991),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                card.word,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _result(BuildContext context, DecoderState state) {
    final winnerIndex = state.winner ?? 0;
    final winnerTeam = state.teams.length > winnerIndex
        ? state.teams[winnerIndex]
        : const Team(id: 'w', name: 'تیم اول', colorValue: 0xFF6750A4);
    final loserIndex = 1 - winnerIndex;
    final loserTeam = state.teams.length > loserIndex
        ? state.teams[loserIndex]
        : const Team(id: 'l', name: 'تیم دوم', colorValue: 0xFF168A86);
    final result = GameResult.fromTeams([
      winnerTeam.copyWith(score: 1),
      loserTeam.copyWith(score: 0),
    ]);
    return GameCompletionView(
      gameKey: 'decoder',
      result: result,
      onComplete: () => Navigator.of(context).pop(true),
      onPlayAgain: _cubit.reset,
    );
  }
}

class _FlipCard extends StatelessWidget {
  final bool revealed;
  final Widget child;
  const _FlipCard({required this.revealed, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(revealed),
    tween: Tween(begin: revealed ? 0.0 : 1.0, end: 1.0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 350),
    curve: Curves.easeOut,
    builder: (context, value, child) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY((1 - value) * math.pi / 2),
      child: child,
    ),
    child: child,
  );
}
