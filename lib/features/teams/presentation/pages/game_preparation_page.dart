import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/game_mode.dart';
import '../../../../core/models/game_setup_config.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/game_emblem.dart';
import '../../../../core/widgets/how_to_play_sheet.dart';
import '../../../../core/widgets/member_name_dialog.dart';
import '../../../../core/widgets/team_identity.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_card.dart';
import '../../../../core/widgets/party_dialog.dart';
import '../cubit/teams_cubit.dart';
import '../cubit/teams_state.dart';

class GamePreparationPage extends StatefulWidget {
  const GamePreparationPage({super.key, required this.gameKey});
  final String gameKey;

  @override
  State<GamePreparationPage> createState() => _GamePreparationPageState();
}

class _GamePreparationPageState extends State<GamePreparationPage> {
  late GameSetupConfig _config = GameSetupConfig.initial(widget.gameKey);
  String? _error;

  Future<void> _addMember(String teamId) async {
    final name = await MemberNameDialog.show(context);
    if (!mounted || name == null) return;
    if (name.isEmpty) {
      setState(() => _error = 'نام بازیکن را وارد کنید.');
      return;
    }
    context.read<TeamsCubit>().addPlayer(name: name, teamId: teamId);
    setState(() => _error = null);
  }

  Future<void> _editTeam(Team team) async {
    final cubit = context.read<TeamsCubit>();
    final appearance = await TeamAppearanceSheet.show(context, team);
    if (!mounted || appearance == null) return;
    cubit.updateTeamAppearance(
      team.id,
      colorValue: appearance.$1,
      iconKey: appearance.$2,
    );
  }

  Future<void> _start(TeamsState state) async {
    final error = GameSetupRequirements.validate(
      widget.gameKey,
      state.teams,
      state.players,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (sl.isRegistered<StorageService>() &&
        sl<StorageService>().getGameSession(widget.gameKey) != null) {
      final confirmed = await PartyDialog.show(
        context,
        title: 'شروع بازی تازه',
        message: 'دست ذخیره‌شدهٔ این بازی جایگزین می‌شود. ادامه می‌دهید؟',
        confirmLabel: 'شروع تازه',
      );
      if (confirmed != true || !mounted) return;
    }
    context.read<TeamsCubit>().resetAllScores();
    Navigator.pushNamed(
      context,
      '/game/${widget.gameKey}',
      arguments: _config.toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameInfo.allGames.firstWhere((g) => g.key == widget.gameKey);
    final minimum = GameSetupConfig.minimumMembers(widget.gameKey);
    return Scaffold(
      appBar: AppBar(
        title: Text(game.titleFa),
        actions: [
          IconButton(
            tooltip: 'آموزش بازی',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => HowToPlaySheet.show(context, widget.gameKey),
          ),
        ],
      ),
      body: AnimatedPartyBackground(
        gameKey: widget.gameKey,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BlocBuilder<TeamsCubit, TeamsState>(
                builder: (context, state) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    GameEmblem(gameKey: widget.gameKey, size: 92),
                    const SizedBox(height: 12),
                    Text(
                      'آماده‌سازی ${game.titleFa}',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.subtitleFa,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    if (GameSetupConfig.hasRoundDuration(widget.gameKey)) ...[
                      _choiceCard(
                        title: 'زمان هر نوبت',
                        icon: Icons.timer_outlined,
                        values: GameSetupConfig.allowedSeconds,
                        selected: _config.roundSeconds!,
                        suffix: 'ثانیه',
                        onSelected: (value) => setState(
                          () => _config = _config.copyWith(roundSeconds: value),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (GameSetupConfig.hasRounds(widget.gameKey)) ...[
                      _choiceCard(
                        title: 'تعداد دور',
                        icon: Icons.repeat_rounded,
                        values: GameSetupConfig.allowedRounds,
                        selected: _config.totalRounds,
                        suffix: 'دور',
                        onSelected: (value) => setState(
                          () => _config = _config.copyWith(totalRounds: value),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    PartyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            minimum > 0
                                ? 'تیم‌ها و بازیکنان *'
                                : 'تیم‌های بازی *',
                            style: AppTypography.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          if (minimum > 0)
                            Text(
                              'هر تیم دست‌کم $minimum عضو لازم دارد.',
                              style: AppTypography.bodyMedium,
                            ),
                          const SizedBox(height: 12),
                          for (final team in state.teams) ...[
                            const Divider(),
                            Row(
                              children: [
                                TeamAvatar(team: team, size: 40),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    team.name,
                                    style: AppTypography.titleLarge,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'رنگ و نشان تیم',
                                  onPressed: () => _editTeam(team),
                                  icon: const Icon(Icons.palette_outlined),
                                ),
                                if (minimum > 0)
                                  TextButton.icon(
                                    onPressed: () => _addMember(team.id),
                                    icon: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                    ),
                                    label: const Text('عضو'),
                                  ),
                              ],
                            ),
                            if (minimum > 0)
                              Wrap(
                                spacing: 6,
                                children: [
                                  for (final player in state.players.where(
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
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/teams'),
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('مدیریت تیم‌ها'),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    PartyButton(
                      label: 'شروع بازی',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _start(state),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    required IconData icon,
    required List<int> values,
    required int selected,
    required String suffix,
    required ValueChanged<int> onSelected,
  }) => PartyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.headlineMedium),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text('$value $suffix'),
                selected: selected == value,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surfaceLight,
                checkmarkColor: AppColors.background,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: selected == value
                      ? AppColors.background
                      : AppColors.textHeadline,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected == value
                      ? AppColors.accent
                      : AppColors.surfaceBorder,
                  width: selected == value ? 2 : 1,
                ),
                onSelected: (_) {
                  if (sl.isRegistered<AudioService>()) {
                    sl<AudioService>().play(GameSound.select);
                  }
                  onSelected(value);
                },
              ),
          ],
        ),
      ],
    ),
  );
}
