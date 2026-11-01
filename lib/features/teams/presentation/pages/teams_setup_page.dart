import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_card.dart';
import '../../../../core/widgets/party_dialog.dart';
import '../cubit/teams_cubit.dart';
import '../cubit/teams_state.dart';

// Team and Player Setup Page (Zero setState)
class TeamsSetupPage extends StatelessWidget {
  const TeamsSetupPage({super.key});

  void _showAddTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final selectedColorValue = ValueNotifier<int>(AppColors.teamPalette.first.toARGB32());

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceBorder, width: 2),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('افزودن تیم جدید', style: AppTypography.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'نام تیم (مثلاً: ببرهای تیزپا)',
                  hintStyle: AppTypography.bodyMedium,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 18),
              const Text('انتخاب رنگ تیم:', style: AppTypography.bodySmall),
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: selectedColorValue,
                builder: (context, currentColor, _) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppColors.teamPalette.map((c) {
                      final isSelected = c.toARGB32() == currentColor;
                      return GestureDetector(
                        onTap: () => selectedColorValue.value = c.toARGB32(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              PartyButton(
                label: 'ایجاد تیم',
                color: AppColors.success,
                onPressed: () {
                  final name = nameController.text.trim();
                  context.read<TeamsCubit>().addTeam(
                        name: name,
                        colorValue: selectedColorValue.value,
                      );
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, List<Team> teams) {
    final nameController = TextEditingController();
    final selectedTeamId = ValueNotifier<String?>(teams.isNotEmpty ? teams.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceBorder, width: 2),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('افزودن بازیکن', style: AppTypography.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'نام بازیکن (مثلاً: سارا، علی...)',
                  hintStyle: AppTypography.bodyMedium,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 18),
              const Text('عضویت در تیم:', style: AppTypography.bodySmall),
              const SizedBox(height: 8),
              ValueListenableBuilder<String?>(
                valueListenable: selectedTeamId,
                builder: (context, teamId, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: teamId,
                    dropdownColor: AppColors.surface,
                    style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: teams
                        .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) => selectedTeamId.value = val,
                  );
                },
              ),
              const SizedBox(height: 24),
              PartyButton(
                label: 'ثبت بازیکن',
                color: AppColors.primary,
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    context.read<TeamsCubit>().addPlayer(
                          name: name,
                          teamId: selectedTeamId.value,
                        );
                  }
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت تیم‌ها و بازیکنان'),
        actions: [
          IconButton(
            tooltip: 'صفر کردن امتیازها',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: () async {
              final confirmed = await PartyDialog.show(
                context,
                title: 'صفر کردن امتیازها',
                message: 'آیا می‌خواهید امتیاز تمام تیم‌ها برای شروع بازی جدید صفر شود؟',
                confirmLabel: 'بله، صفر کن',
              );
              if (confirmed == true && context.mounted) {
                context.read<TeamsCubit>().resetAllScores();
              }
            },
          ),
        ],
      ),
      body: AnimatedPartyBackground(
        child: BlocBuilder<TeamsCubit, TeamsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Header card
                PartyCard(
                  gradient: AppColors.purpleGradient,
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 48, color: Colors.white),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تیم‌های مسابقه', style: AppTypography.headlineLarge),
                            const SizedBox(height: 4),
                            Text(
                              '${state.teams.length} تیم و ${state.players.length} بازیکن ثبت شده',
                              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Teams Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('لیست تیم‌ها', style: AppTypography.headlineMedium),
                    IconButton(
                      tooltip: 'افزودن تیم',
                      icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 30),
                      onPressed: () => _showAddTeamDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...state.teams.map((team) {
                  final teamPlayers = state.players.where((p) => p.teamId == team.id).toList();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(team.colorValue), width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(team.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                team.name,
                                style: AppTypography.headlineMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'امتیاز: ${team.score}',
                                style: AppTypography.titleLarge.copyWith(color: AppColors.accent),
                              ),
                            ),
                            if (state.teams.length > 2) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => context.read<TeamsCubit>().removeTeam(team.id),
                              ),
                            ],
                          ],
                        ),
                        if (teamPlayers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: teamPlayers.map((player) {
                              return Chip(
                                backgroundColor: AppColors.surfaceLight,
                                label: Text(player.name, style: AppTypography.bodySmall),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => context.read<TeamsCubit>().removePlayer(player.id),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Add player button
                PartyButton(
                  label: 'افزودن بازیکن جدید',
                  icon: Icons.person_add_rounded,
                  color: AppColors.surfaceLight,
                  textColor: AppColors.textHeadline,
                  shadowColor: AppColors.surfaceBorder,
                  onPressed: () => _showAddPlayerDialog(context, state.teams),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
