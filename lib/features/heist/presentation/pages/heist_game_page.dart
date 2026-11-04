import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/heist_catalog.dart';
import '../../domain/heist_models.dart';
import '../cubit/heist_cubit.dart';
import '../widgets/heist_art.dart';

class HeistGamePage extends StatelessWidget {
  const HeistGamePage({super.key, this.resumeSaved = false});
  final bool resumeSaved;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HeistCubit(resume: resumeSaved),
    child: const _HeistView(),
  );
}

class _HeistView extends StatefulWidget {
  const _HeistView();

  @override
  State<_HeistView> createState() => _HeistViewState();
}

class _HeistViewState extends State<_HeistView> with WidgetsBindingObserver {
  late final HeistCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<HeistCubit>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.resumeMusic();
    } else {
      _cubit.pauseMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080A0F),
    body: HeistBackdrop(
      hero: true,
      child: BlocBuilder<HeistCubit, HeistState>(
        builder: (context, state) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          child: _PhaseBody(key: ValueKey(state.phase), state: state),
        ),
      ),
    ),
  );
}

class _PhaseBody extends StatelessWidget {
  const _PhaseBody({super.key, required this.state});
  final HeistState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HeistCubit>();
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xE6080A0F),
          foregroundColor: const Color(0xFFF4E9D3),
          title: Text(
            state.phase == HeistPhase.setup
                ? 'سرقت بزرگ'
                : 'سرقت ${state.heistIndex + 1} از 3',
          ),
          actions: [
            if (state.phase != HeistPhase.setup)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 14),
                child: Center(
                  child: Text(
                    'هشدار ${state.alarm}',
                    style: const TextStyle(color: Color(0xFFFF6878)),
                  ),
                ),
              ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 42),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _content(context, cubit),
                    if (state.message != null) ...[
                      const SizedBox(height: 14),
                      _Notice(state.message!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, HeistCubit cubit) =>
      switch (state.phase) {
        HeistPhase.setup => _Setup(state: state, cubit: cubit),
        HeistPhase.rolePass => _PrivateGate(
          name: cubit.rolePlayer.name,
          title: 'پرونده محرمانه نقش',
          action: 'مشاهده نقش',
          onTap: cubit.revealRole,
        ),
        HeistPhase.roleReveal => _RoleReveal(
          player: cubit.rolePlayer,
          role: cubit.roleOf(cubit.rolePlayer),
          onDone: cubit.hideRole,
        ),
        HeistPhase.planning => _Planning(state: state, cubit: cubit),
        HeistPhase.operation => _Operation(state: state, cubit: cubit),
        HeistPhase.secretPass => _PrivateGate(
          name: cubit.secretPlayer.name,
          title: 'تصمیم محرمانه عملیات',
          action: 'ورود امن',
          onTap: cubit.openSecretChoice,
        ),
        HeistPhase.secretChoice => _SecretChoice(
          player: cubit.secretPlayer,
          role: cubit.roleOf(cubit.secretPlayer),
          onTap: cubit.chooseSecret,
        ),
        HeistPhase.operationReveal => _OperationResult(
          state: state,
          cubit: cubit,
        ),
        HeistPhase.accusation => _Accusation(state: state, cubit: cubit),
        HeistPhase.division => _Division(state: state, cubit: cubit),
        HeistPhase.votePass => _PrivateGate(
          name: state.players[state.voteIndex].name,
          title: 'رأی‌گیری محرمانه',
          action: 'مشاهده پیشنهاد و رأی',
          onTap: cubit.openVote,
        ),
        HeistPhase.voteChoice => _Vote(state: state, cubit: cubit),
        HeistPhase.heistSummary => _Summary(state: state, cubit: cubit),
        HeistPhase.finalResult => _Final(cubit: cubit),
      };
}

class _Setup extends StatelessWidget {
  const _Setup({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 120),
      const Text(
        'THE GREAT HEIST',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFE6B85C),
          letterSpacing: 4,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Text(
        'سرقت بزرگ',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w900,
        ),
      ),
      const Text(
        'سه عملیات. نقش‌های مخفی. یک غنیمت که دوستی‌ها را امتحان می‌کند.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFD2C9BA), height: 1.7),
      ),
      const SizedBox(height: 28),
      HeistPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Title('تعداد اعضای گروه'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var n = 4; n <= 8; n++)
                  ChoiceChip(
                    label: Text('$n'),
                    selected: state.names.length == n,
                    selectedColor: const Color(0xFFE6B85C),
                    backgroundColor: const Color(0xFF101218),
                    checkmarkColor: const Color(0xFF17120A),
                    side: BorderSide(
                      color: state.names.length == n
                          ? const Color(0xFFFFE2A0)
                          : const Color(0xFF655338),
                      width: state.names.length == n ? 1.8 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: state.names.length == n
                          ? const Color(0xFF17120A)
                          : const Color(0xFFF4E9D3),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                    onSelected: (_) => cubit.setPlayerCount(n),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const _Title('اسم رمز بازیکن‌ها'),
            for (var i = 0; i < state.names.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: TextFormField(
                  key: ValueKey('heist-name-$i-${state.names.length}'),
                  initialValue: state.names[i],
                  onChanged: (v) => cubit.renamePlayer(i, v),
                  decoration: InputDecoration(
                    labelText: 'بازیکن ${i + 1}',
                    filled: true,
                    fillColor: const Color(0xFF101218),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const _Title('سطح امنیت'),
            SegmentedButton<HeistDifficulty>(
              segments: [
                for (final d in HeistDifficulty.values)
                  ButtonSegment(value: d, label: Text(d.titleFa)),
              ],
              selected: {state.difficulty},
              onSelectionChanged: (v) => cubit.setDifficulty(v.first),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Text(
                state.difficulty.detailFa,
                key: ValueKey(state.difficulty),
                style: const TextStyle(color: Color(0xFFD2C9BA), height: 1.5),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      HeistPanel(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _Stat('3', 'سرقت'),
            _Stat('8', 'نقش'),
            _Stat('30', 'بحران'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      HeistButton(
        label: 'آموزش بازی',
        secondary: true,
        onPressed: () => _openHeistTutorial(context),
      ),
      const SizedBox(height: 10),
      HeistButton(
        label: 'تشکیل گروه و شروع پرونده',
        onPressed: cubit.startGame,
      ),
    ],
  );
}

class _PrivateGate extends StatelessWidget {
  const _PrivateGate({
    required this.name,
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String name, title, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HeistPanel(
    child: Column(
      children: [
        const SizedBox(height: 36),
        const Icon(
          Icons.lock_outline_rounded,
          size: 54,
          color: Color(0xFFE6B85C),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          'گوشی را فقط به «$name» بدهید. بقیه نگاه نکنند.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFD2C9BA), height: 1.7),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: HeistButton(label: '$name، $action', onPressed: onTap),
        ),
      ],
    ),
  );
}

class _RoleReveal extends StatelessWidget {
  const _RoleReveal({
    required this.player,
    required this.role,
    required this.onDone,
  });
  final HeistPlayer player;
  final HeistRole role;
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _RolePortrait(index: role.atlasIndex, maxSize: 380),
      const SizedBox(height: 14),
      HeistPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${player.name}، تو «${role.title}» هستی',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _Line('توانایی', role.ability),
            _Line('نقطه قوت', role.strength),
            _Line('نقطه ضعف', role.weakness),
            _Line('هدف شخصی مخفی (+200)', role.objective),
            const SizedBox(height: 12),
            HeistButton(label: 'نقش را حفظ کردم؛ پنهانش کن', onPressed: onDone),
          ],
        ),
      ),
    ],
  );
}

class _Planning extends StatelessWidget {
  const _Planning({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) {
    final bank = cubit.currentBank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 250,
          child: HeistAtlasTile(
            asset: 'assets/heist/heist_banks_atlas.png',
            columns: 5,
            rows: 1,
            index: bank.atlasIndex,
          ),
        ),
        const SizedBox(height: 14),
        HeistPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bank.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'رهبر عملیات: ${cubit.leader.name}  •  امنیت ${bank.security}/5  •  پایه غنیمت ${_money(bank.baseLoot)}',
                style: const TextStyle(color: Color(0xFFE6B85C)),
              ),
              const SizedBox(height: 8),
              Text(bank.description),
              const SizedBox(height: 10),
              _MissionBrief(
                target: cubit.operationTarget,
                alarmLimit: cubit.alarmLimit,
              ),
              const SizedBox(height: 18),
              const _Title('مسیر نفوذ'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in HeistApproach.values)
                    ChoiceChip(
                      label: Text(p.titleFa),
                      avatar: Icon(
                        _approachIcon(p),
                        size: 19,
                        color: state.plan == p
                            ? Colors.white
                            : _approachColor(p),
                      ),
                      selected: state.plan == p,
                      selectedColor: _approachColor(p),
                      backgroundColor: const Color(0xFF20232B),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: state.plan == p
                            ? _approachColor(p).withValues(alpha: .95)
                            : _approachColor(p).withValues(alpha: .4),
                        width: state.plan == p ? 2 : 1,
                      ),
                      labelStyle: TextStyle(
                        color: state.plan == p
                            ? Colors.white
                            : const Color(0xFFF4E9D3),
                        fontWeight: FontWeight.w900,
                      ),
                      onSelected: (_) => cubit.choosePlan(p),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const _Title('تجهیز اصلی'),
              for (final entry in HeistCatalog.equipment.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Material(
                    color: state.equipment == entry.key
                        ? const Color(0x2227B8A7)
                        : const Color(0x66101218),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: state.equipment == entry.key
                            ? const Color(0xFF5FBCB0)
                            : const Color(0x335E4B2B),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioListTile<String>(
                      dense: true,
                      value: entry.key,
                      groupValue: state.equipment,
                      activeColor: const Color(0xFFE6B85C),
                      selected: state.equipment == entry.key,
                      onChanged: (v) {
                        if (v != null) cubit.chooseEquipment(v);
                      },
                      title: Text(entry.value),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              HeistButton(label: 'اجرای نقشه', onPressed: cubit.beginOperation),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionBrief extends StatelessWidget {
  const _MissionBrief({required this.target, required this.alarmLimit});

  final int target;
  final int alarmLimit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x22168A86),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x555FBCB0)),
    ),
    child: Row(
      children: [
        const Icon(Icons.assignment_rounded, color: Color(0xFF5FBCB0)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'شرط عملیات: حداقل $target امتیاز و حداکثر $alarmLimit هشدار',
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _Operation extends StatelessWidget {
  const _Operation({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) {
    final event = cubit.currentEvent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (state.eventIndex + 1) / state.eventIds.length,
          minHeight: 7,
          color: const Color(0xFFE6B85C),
        ),
        const SizedBox(height: 12),
        _OperationHud(state: state, cubit: cubit),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.08, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(event.id),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 270,
                child: HeistAtlasTile(
                  asset: 'assets/heist/heist_events_atlas.png',
                  columns: 3,
                  rows: 2,
                  index: event.artIndex,
                ),
              ),
              const SizedBox(height: 14),
              HeistPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'بحران ${state.eventIndex + 1}: ${event.title}',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(event.description),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RiskBadge(
                          icon: Icons.warning_amber_rounded,
                          label: 'خطر ${event.danger}',
                          color: const Color(0xFFFF6878),
                        ),
                        _RiskBadge(
                          icon: Icons.savings_rounded,
                          label: 'پاداش ${_money(event.reward)}',
                          color: const Color(0xFFE6B85C),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final p in HeistApproach.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: HeistButton(
                          label: p.titleFa,
                          secondary: p != state.plan,
                          onPressed: () => cubit.resolveEvent(p),
                        ),
                      ),
                  ],
                ),
              ),
              if (state.report.isNotEmpty) ...[
                const SizedBox(height: 10),
                _MissionFeedback(text: state.report.last),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OperationHud extends StatelessWidget {
  const _OperationHud({required this.state, required this.cubit});

  final HeistState state;
  final HeistCubit cubit;

  @override
  Widget build(BuildContext context) => HeistPanel(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: _MissionMeter(
            label: 'عملیات',
            value: state.operationScore,
            target: cubit.operationTarget,
            color: const Color(0xFF5FBCB0),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MissionMeter(
            label: 'هشدار',
            value: state.alarm,
            target: cubit.alarmLimit,
            color: const Color(0xFFFF6878),
            inverse: true,
          ),
        ),
      ],
    ),
  );
}

class _MissionMeter extends StatelessWidget {
  const _MissionMeter({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.inverse = false,
  });

  final String label;
  final int value;
  final int target;
  final Color color;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inverse ? '$label $value / سقف $target' : '$label $value / $target',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            color: color,
            backgroundColor: color.withValues(alpha: .14),
          ),
        ),
      ],
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _MissionFeedback extends StatelessWidget {
  const _MissionFeedback({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final success = text.contains('واکنش درست') || text.contains('EMP');
    final color = success ? const Color(0xFF5FBCB0) : const Color(0xFFFF6878);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

Color _approachColor(HeistApproach approach) => switch (approach) {
  HeistApproach.stealth => const Color(0xFF168A86),
  HeistApproach.technology => const Color(0xFF3279C8),
  HeistApproach.force => const Color(0xFFC93645),
  HeistApproach.social => const Color(0xFF7656B8),
};

IconData _approachIcon(HeistApproach approach) => switch (approach) {
  HeistApproach.stealth => Icons.visibility_off_rounded,
  HeistApproach.technology => Icons.memory_rounded,
  HeistApproach.force => Icons.hardware_rounded,
  HeistApproach.social => Icons.badge_rounded,
};

class _SecretChoice extends StatelessWidget {
  const _SecretChoice({
    required this.player,
    required this.role,
    required this.onTap,
  });
  final HeistPlayer player;
  final HeistRole role;
  final ValueChanged<HeistSecretAction> onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          SizedBox.square(
            dimension: 100,
            child: HeistAtlasTile(
              asset: 'assets/heist/heist_roles_atlas_v2.png',
              columns: 4,
              rows: 2,
              index: role.atlasIndex,
              borderRadius: 14,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${player.name}\n${role.title}',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      for (final action in HeistSecretAction.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HeistPanel(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  action.titleFa,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(
                  action == HeistSecretAction.ability
                      ? role.ability
                      : action.detailFa,
                  style: const TextStyle(color: Color(0xFFD2C9BA)),
                ),
                const SizedBox(height: 8),
                HeistButton(
                  label: 'انتخاب ${action.titleFa}',
                  danger:
                      action == HeistSecretAction.sabotage ||
                      action == HeistSecretAction.steal,
                  secondary:
                      action == HeistSecretAction.cooperate ||
                      action == HeistSecretAction.protect,
                  onPressed: () => onTap(action),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _OperationResult extends StatelessWidget {
  const _OperationResult({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) => HeistPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'گزارش خروج از خزانه',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(_money(state.loot), 'غنیمت'),
            _Stat('${state.alarm}', 'هشدار'),
            _Stat('${state.operationScore}', 'عملیات'),
          ],
        ),
        const Divider(height: 30),
        for (final line in state.report)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('• $line'),
          ),
        const SizedBox(height: 12),
        HeistButton(
          label: 'جلسه اتهام',
          danger: true,
          onPressed: cubit.openAccusation,
        ),
      ],
    ),
  );
}

class _Accusation extends StatelessWidget {
  const _Accusation({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) => HeistPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'یک اتهام، یک فرصت',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const Text(
          'گروه می‌تواند یک نفر را متهم کند. اتهام اشتباه برای رهبر جریمه دارد.',
          style: TextStyle(color: Color(0xFFD2C9BA)),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < state.players.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HeistButton(
              label: 'اتهام به ${state.players[i].name}',
              danger: true,
              secondary: true,
              onPressed: () => cubit.accuse(i),
            ),
          ),
        HeistButton(
          label: 'اتهامی نداریم',
          onPressed: () => cubit.accuse(null),
        ),
      ],
    ),
  );
}

class _Division extends StatelessWidget {
  const _Division({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) => HeistPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تقسیم غنیمت توسط ${cubit.leader.name}',
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        Text(
          'کل قابل تقسیم: ${_money(state.loot)}',
          style: const TextStyle(color: Color(0xFFE6B85C)),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < state.players.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF101218),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${state.players[i].name}${i == state.leaderIndex ? ' (رهبر)' : ''}',
                  ),
                ),
                if (i != state.leaderIndex)
                  IconButton(
                    onPressed: () => cubit.shiftShare(i, -500),
                    icon: const Icon(Icons.remove),
                  ),
                Text(
                  _money(state.proposal[i]),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (i != state.leaderIndex)
                  IconButton(
                    onPressed: () => cubit.shiftShare(i, 500),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
          ),
        TextButton(
          onPressed: cubit.resetEqualProposal,
          child: const Text('بازنشانی تقسیم برابر'),
        ),
        HeistButton(
          label: 'ارسال پیشنهاد برای رأی مخفی',
          onPressed: state.proposalTotal == state.loot
              ? cubit.submitProposal
              : null,
        ),
      ],
    ),
  );
}

class _Vote extends StatelessWidget {
  const _Vote({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) => HeistPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${state.players[state.voteIndex].name}، پیشنهاد را بررسی کن',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < state.players.length; i++)
          ListTile(
            title: Text(state.players[i].name),
            trailing: Text(
              _money(state.proposal[i]),
              style: const TextStyle(
                color: Color(0xFFE6B85C),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: HeistButton(
                label: 'رد می‌کنم',
                danger: true,
                onPressed: () => cubit.castVote(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HeistButton(
                label: 'موافقم',
                onPressed: () => cubit.castVote(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.cubit});
  final HeistState state;
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) => HeistPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'پایان سرقت ${state.heistIndex + 1}',
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        if (state.message != null)
          Text(
            state.message!,
            style: const TextStyle(color: Color(0xFFE6B85C)),
          ),
        const SizedBox(height: 14),
        for (var i = 0; i < cubit.rankedPlayers.length; i++)
          ListTile(
            leading: CircleAvatar(child: Text('${cubit.rankedPositions[i]}')),
            title: Text(cubit.rankedPlayers[i].name),
            subtitle: Text('ظن ${cubit.rankedPlayers[i].suspicion}/10'),
            trailing: Text(
              _money(cubit.rankedPlayers[i].cash),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        const SizedBox(height: 12),
        HeistButton(
          label: state.isLastHeist
              ? 'افشای نتیجه نهایی'
              : 'آماده‌سازی سرقت بعدی',
          onPressed: cubit.continueAfterSummary,
        ),
      ],
    ),
  );
}

class _Final extends StatelessWidget {
  const _Final({required this.cubit});
  final HeistCubit cubit;
  @override
  Widget build(BuildContext context) {
    final winner = cubit.rankedPlayers.first;
    final role = cubit.roleOf(winner);
    return Column(
      children: [
        const Text(
          'پرونده بسته شد',
          style: TextStyle(color: Color(0xFFE6B85C), letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        _RolePortrait(index: role.atlasIndex, maxSize: 340),
        const SizedBox(height: 14),
        HeistPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${winner.name}، سلطان سرقت',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${role.title} • ${_money(winner.cash)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFE6B85C)),
              ),
              const Divider(height: 28),
              for (var i = 0; i < cubit.rankedPlayers.length; i++)
                ListTile(
                  title: Text(
                    '${cubit.rankedPositions[i]}. ${cubit.rankedPlayers[i].name}',
                  ),
                  trailing: Text(_money(cubit.rankedPlayers[i].cash)),
                ),
              const SizedBox(height: 10),
              HeistButton(
                label: 'بازگشت به مخفیگاه',
                onPressed: () {
                  cubit.finishAndClear();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolePortrait extends StatelessWidget {
  const _RolePortrait({required this.index, required this.maxSize});
  final int index;
  final double maxSize;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
      child: AspectRatio(
        aspectRatio: 1,
        child: HeistAtlasTile(
          asset: 'assets/heist/heist_roles_atlas_v2.png',
          columns: 4,
          rows: 2,
          index: index,
        ),
      ),
    ),
  );
}

void _openHeistTutorial(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _HeistTutorial(),
  );
}

class _HeistTutorial extends StatelessWidget {
  const _HeistTutorial();

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .9,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0C0E13),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Color(0xFF80642E))),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF786A53),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'آموزش سرقت بزرگ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'بازی 4 تا 8 نفره با یک گوشی • حدود 15 تا 25 دقیقه',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFE6B85C)),
          ),
          const SizedBox(height: 18),
          const _TutorialInfoBox(
            title: 'داستان و هدف بازی',
            icon: Icons.flag_rounded,
            text: 'شما اعضای یک گروه سرقت هستید. برای بازکردن گاوصندوق باید با هم همکاری کنید، اما هر نفر نقش، توانایی و هدف شخصی خودش را دارد. بازی شامل 3 سرقت است و در پایان، بازیکنی که بیشترین پول را جمع کرده باشد برنده می‌شود؛ پس هم به گروه نیاز دارید و هم باید مراقب خیانت دیگران باشید.',
          ),
          const _TutorialInfoBox(
            title: 'قبل از شروع بدانید',
            icon: Icons.groups_rounded,
            text: 'تیم ثابت وجود ندارد. یک گوشی بین همه می‌چرخد و اطلاعات شخصی فقط باید توسط صاحب گوشی دیده شود. نقش‌ها تا پایان مخفی می‌مانند و رهبر هر سرقت مسئول انتخاب نقشه و پیشنهاد تقسیم غنیمت است.',
          ),
          const SizedBox(height: 22),
          const _TutorialStep(
            number: '1',
            title: 'نقش مخفی‌ات را بشناس',
            description: 'گوشی دست‌به‌دست می‌شود. هر نفر نقش، تخصص، نقطه قوت، نقطه ضعف، توانایی و هدف شخصی خودش را می‌بیند. توانایی نقش فقط یک‌بار در هر سرقت قابل استفاده است و انجام هدف شخصی، پول اضافه می‌دهد. اطلاعات را حفظ کن و صفحه را پنهان کن.',
            art: _TutorialArt.role,
          ),
          const _TutorialStep(
            number: '2',
            title: 'برای 3 سرقت نقشه بکشید',
            description: 'بانک، میزان امنیت و غنیمت پایه را بررسی کنید. رهبر پس از مشورت با بقیه، یک مسیر ورود و یک تجهیز انتخاب می‌کند. هماهنگی مسیر و تجهیز امتیاز اولیه عملیات را بالا می‌برد؛ مثلاً حمله سایبری با مختل‌کننده سیگنال هماهنگ است.',
            art: _TutorialArt.bank,
          ),
          const _TutorialStep(
            number: '3',
            title: 'از 4 بحران عبور کنید',
            description: 'در هر سرقت 4 بحران نمایش داده می‌شود. گروه برای هر بحران یکی از چهار واکنش را انتخاب می‌کند. واکنش درست امتیاز عملیات و غنیمت را بیشتر می‌کند؛ واکنش اشتباه امتیاز را کم و سطح هشدار را زیاد می‌کند. تخصص نقش‌های حاضر هم می‌تواند کمک کند.',
            art: _TutorialArt.event,
          ),
          const _TutorialStep(
            number: '4',
            title: 'هر نفر مخفیانه تصمیم می‌گیرد',
            description: 'گوشی دوباره نفر‌به‌نفر می‌چرخد. هیچ‌کس نباید انتخاب بقیه را ببیند. تصمیم‌ها روی موفقیت عملیات، مقدار غنیمت، میزان ظن و پول شخصی اثر می‌گذارند.',
            art: _TutorialArt.role,
          ),
          const _SecretActionGuide(),
          const _TutorialStep(
            number: '5',
            title: 'نتیجه عملیات را تحلیل کنید',
            description: 'بازی امتیاز عملیات، امنیت بانک و سطح هشدار را بررسی می‌کند. اگر گروه خوب عمل کرده باشد گاوصندوق با غنیمت کامل باز می‌شود؛ در عملیات ضعیف یا پرهشدار، بخشی از پول هنگام فرار از دست می‌رود. گزارش عملیات تعداد حرکت‌های مشکوک و افراد شناسایی‌شده را نشان می‌دهد.',
            art: _TutorialArt.event,
          ),
          const _TutorialStep(
            number: '6',
            title: 'فقط یک اتهام بزنید',
            description: 'گروه می‌تواند یک نفر را متهم کند یا از اتهام بگذرد. اگر متهم واقعاً دزدی یا خرابکاری کرده باشد، پول مخفی او به غنیمت برمی‌گردد و خودش جریمه می‌شود. اگر اتهام اشتباه باشد، رهبر جریمه پرداخت می‌کند؛ پس بدون مدرک ریسک نکنید.',
            art: _TutorialArt.role,
          ),
          const _TutorialStep(
            number: '7',
            title: 'غنیمت را تقسیم و رأی‌گیری کنید',
            description: 'رهبر باید تمام غنیمت را بین بازیکنان پیشنهاد دهد. سپس گوشی می‌چرخد و همه مخفیانه موافق یا مخالف رأی می‌دهند. رأی اکثریت پیشنهاد را تصویب می‌کند. اگر رد شود، 15٪ غنیمت از بین می‌رود و رهبر عوض می‌شود؛ با رد پیشنهاد دوم، تقسیم برابر اجباری اجرا می‌شود.',
            art: _TutorialArt.vault,
          ),
          const _TutorialInfoBox(
            title: 'قانون ویژه مذاکره‌کننده',
            icon: Icons.how_to_vote_rounded,
            text: 'اگر تعداد رأی موافق و مخالف برابر شود، فقط در صورتی پیشنهاد تصویب می‌شود که بازیکن دارای نقش مذاکره‌کننده رأی موافق داده باشد.',
          ),
          const _TutorialInfoBox(
            title: 'پایان بازی',
            icon: Icons.emoji_events_rounded,
            text: 'بعد از تقسیم پول، سرقت بعدی با رهبر جدید شروع می‌شود. ظن بازیکنان کاملاً پاک نمی‌شود، پس خیانت‌های قبلی می‌توانند در سرقت بعدی خطرناک باشند. پس از سرقت سوم، رتبه‌بندی براساس کل پول هر بازیکن انجام می‌شود.',
          ),
          const _TutorialExample(),
          const SizedBox(height: 8),
          HeistButton(
            label: 'فهمیدم، آماده سرقتم',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

class _TutorialInfoBox extends StatelessWidget {
  const _TutorialInfoBox({
    required this.title,
    required this.icon,
    required this.text,
  });

  final String title;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xCC171B22),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x665FBCB0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF5FBCB0), size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE6B85C),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(color: Color(0xFFD2C9BA), height: 1.65),
        ),
      ],
    ),
  );
}

class _SecretActionGuide extends StatelessWidget {
  const _SecretActionGuide();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: HeistPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'معنی انتخاب‌های مخفی',
            style: TextStyle(
              color: Color(0xFFE6B85C),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final action in HeistSecretAction.values)
            _SecretActionLine(
              title: action.titleFa,
              description: action.detailFa,
            ),
        ],
      ),
    ),
  );
}

class _SecretActionLine extends StatelessWidget {
  const _SecretActionLine({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, size: 7, color: Color(0xFF5FBCB0)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: description),
              ],
            ),
            style: const TextStyle(color: Color(0xFFD2C9BA), height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class _TutorialExample extends StatelessWidget {
  const _TutorialExample();

  @override
  Widget build(BuildContext context) => const _TutorialInfoBox(
    title: 'مثال یک سرقت',
    icon: Icons.lightbulb_rounded,
    text: 'فرض کنید بانک به واکنش سایبری نیاز دارد. گروه «حمله سایبری» و «مختل‌کننده سیگنال» را انتخاب می‌کند و در بحران‌ها تصمیم‌های درستی می‌گیرد. هنگام انتخاب مخفی، سه نفر همکاری می‌کنند اما یک نفر برداشت مخفیانه انجام می‌دهد. بعد از عملیات، گروه با توجه به گزارش می‌تواند همان فرد را متهم کند. در پایان، رهبر سهم‌ها را پیشنهاد می‌دهد و اگر اکثریت موافق باشند پول‌ها ثبت و سرقت بعدی آغاز می‌شود.',
  );
}

enum _TutorialArt { role, bank, event, vault }

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.number,
    required this.title,
    required this.description,
    required this.art,
  });
  final String number;
  final String title;
  final String description;
  final _TutorialArt art;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: HeistPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(dimension: 92, child: _art()),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    color: Color(0xFFE6B85C),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFD2C9BA),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _art() => switch (art) {
    _TutorialArt.role => const HeistAtlasTile(
      asset: 'assets/heist/heist_roles_atlas_v2.png',
      columns: 4,
      rows: 2,
      index: 0,
      borderRadius: 15,
    ),
    _TutorialArt.bank => const HeistAtlasTile(
      asset: 'assets/heist/heist_banks_atlas.png',
      columns: 5,
      rows: 1,
      index: 1,
      borderRadius: 15,
    ),
    _TutorialArt.event => const HeistAtlasTile(
      asset: 'assets/heist/heist_events_atlas.png',
      columns: 3,
      rows: 2,
      index: 2,
      borderRadius: 15,
    ),
    _TutorialArt.vault => ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        'assets/heist/heist_vault_hero.png',
        fit: BoxFit.cover,
      ),
    ),
  };
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text('$label: $value', style: const TextStyle(height: 1.6)),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFFE6B85C),
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: const TextStyle(color: Color(0xFFD2C9BA))),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xCC5B281F),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x99FF6878)),
    ),
    child: Text(text, textAlign: TextAlign.center),
  );
}

String _money(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '٬')} سکه';
