import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_dialog.dart';
import '../../../../core/widgets/team_identity.dart';
import '../cubit/teams_cubit.dart';
import '../cubit/teams_state.dart';

class TeamsSetupPage extends StatelessWidget {
  const TeamsSetupPage({super.key});

  Future<void> _editTeam(BuildContext context, Team team) async {
    final cubit = context.read<TeamsCubit>();
    final appearance = await TeamAppearanceSheet.show(context, team);
    if (!context.mounted || appearance == null) return;
    cubit.updateTeam(
      team.id,
      name: appearance.$1,
      colorValue: appearance.$2,
      iconKey: appearance.$3,
    );
  }

  void _open(BuildContext context, List<Team> teams) => showDialog<void>(
    context: context,
    builder: (_) =>
        _EntryDialog(cubit: context.read<TeamsCubit>(), teams: teams),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('تیم‌ها و بازیکنان'),
      actions: [
        IconButton(
          tooltip: 'صفر کردن امتیازها',
          icon: const Icon(Icons.restart_alt_rounded),
          onPressed: () async {
            if (await PartyDialog.show(
                      context,
                      title: 'صفر کردن امتیازها',
                      message: 'امتیاز همه تیم‌ها صفر شود؟',
                      confirmLabel: 'صفر کن',
                    ) ==
                    true &&
                context.mounted) {
              context.read<TeamsCubit>().resetAllScores();
            }
          },
        ),
      ],
    ),
    body: AnimatedPartyBackground(
      child: SafeArea(
        top: false,
        child: BlocBuilder<TeamsCubit, TeamsState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Text(
                'جمع‌تون رو بچینید',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${state.teams.length} تیم • ${state.players.length} بازیکن',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('بازیکن جدید'),
                    onPressed: () => _open(context, state.teams),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (final team in state.teams)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Color(team.colorValue).withValues(alpha: .65),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TeamAvatar(team: team),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              team.name,
                              style: AppTypography.headlineMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'ویرایش تیم',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editTeam(context, team),
                          ),
                        ],
                      ),
                      Text(
                        '${team.score} امتیاز',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final player in state.players.where(
                            (p) => p.teamId == team.id,
                          ))
                            Chip(
                              label: Text(player.name),
                              onDeleted: () => context
                                  .read<TeamsCubit>()
                                  .removePlayer(player.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              PartyButton(
                label: 'افزودن بازیکن',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => _open(context, state.teams),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.cubit, required this.teams});
  final TeamsCubit cubit;
  final List<Team> teams;
  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final name = TextEditingController();
  late final ValueNotifier<String?> selectedTeam;
  @override
  void initState() {
    super.initState();
    selectedTeam = ValueNotifier(
      widget.teams.isEmpty ? null : widget.teams.first.id,
    );
  }

  @override
  void dispose() {
    name.dispose();
    selectedTeam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('بازیکن جدید', style: AppTypography.headlineLarge),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'نام بازیکن'),
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<String?>(
            valueListenable: selectedTeam,
            builder: (context, selected, _) => DropdownButtonFormField<String>(
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'تیم'),
              items: [
                for (final t in widget.teams)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (value) => selectedTeam.value = value,
            ),
          ),
          const SizedBox(height: 22),
          PartyButton(
            label: 'ثبت',
            onPressed: () {
              final text = name.text.trim();
              if (text.isEmpty) return;
              widget.cubit.addPlayer(name: text, teamId: selectedTeam.value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
