import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/models/game_setup_config.dart';
import 'package:flutter_application_1/core/widgets/game_scene.dart';
import 'package:flutter_application_1/core/widgets/pass_phone_overlay.dart';
import 'package:flutter_application_1/core/widgets/game_lifecycle_guard.dart';
import 'package:flutter_application_1/core/widgets/game_emblem.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/app/theme/app_typography.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/core/widgets/how_to_play_sheet.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_card.dart';
import 'package:flutter_application_1/core/widgets/party_dialog.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';

import '../cubit/hot_potato_cubit.dart';
import '../cubit/hot_potato_state.dart';
import '../../data/hot_potato_repository.dart';
import '../widgets/bomb_animation_view.dart';

// Hot Potato Game Page (Zero setState)
class HotPotatoGamePage extends StatelessWidget {
  final GameSetupConfig? setup;
  final bool isQuickMode;
  final bool resumeSaved;
  final String? tournamentId;

  const HotPotatoGamePage({
    super.key,
    this.setup,
    this.isQuickMode = false,
    this.resumeSaved = false,
    this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return GameContentGate(
      load: () => sl<HotPotatoRepository>().loadTopics(),
      child: BlocProvider(
        create: (context) => HotPotatoCubit(
          setup: setup,
          repository: sl<HotPotatoRepository>(),
          isQuickMode: isQuickMode,
          resumeSaved: resumeSaved,
          teamsCubit: context.read<TeamsCubit>(),
        ),
        child: Builder(
          builder: (context) => GameLifecycleGuard(
            initiallyCovered: context.read<HotPotatoCubit>().hasRestoredSession,
            onPause: () => context.read<HotPotatoCubit>().pause(),
            onResume: () => context.read<HotPotatoCubit>().resume(),
            child: const _HotPotatoGameView(),
          ),
        ),
      ),
    );
  }
}

class _HotPotatoGameView extends StatelessWidget {
  const _HotPotatoGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HotPotatoCubit, HotPotatoState>(
      builder: (context, state) {
        if (state.isGameOver && !state.isExploded) {
          return GameCompletionView(
            gameKey: 'hot_potato',
            result: context.read<HotPotatoCubit>().result,
            onComplete: () => context.read<HotPotatoCubit>().finishAndClear(),
          );
        }
        if (state.isReadyPhase) {
          return Scaffold(
            body: PassPhoneOverlay(
              teamName: state.holdingTeamOrPlayer,
              gameTitle: 'بمب دست کیه؟',
              onReady: () => context.read<HotPotatoCubit>().startNewRound(),
            ),
          );
        }
        if (state.isExploded) {
          return _buildExplosionResult(context, state);
        }

        return Scaffold(
          appBar: AppBar(
            bottom: const GameSceneRibbon(gameKey: 'hot_potato'),
            title: const Text('بمب دست کیه؟'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                GameLifecycleGuard.of(context).cover();
                final confirm = await PartyDialog.show(
                  context,
                  title: 'خروج از مسابقه بمب',
                  message: 'آیا می‌خواهید از بازی خارج شوید؟',
                  confirmLabel: 'بله، خروج',
                );
                if (confirm == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              const GameEmblem(gameKey: 'hot_potato', size: 36),
              IconButton(
                tooltip: 'راهنمای بازی',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () {
                  GameLifecycleGuard.of(context).cover();
                  HowToPlaySheet.show(context, 'hot_potato');
                },
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            gameKey: 'hot_potato',
            child: SafeArea(
              child: _ScrollableBombStage(
                children: [
                  const SizedBox(height: 12),

                  // Topic Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PartyCard(
                      borderColor: AppColors.bombPrimary,
                      child: Column(
                        children: [
                          Text(
                            state.currentTopic?.topic ?? 'در حال بارگذاری...',
                            style: AppTypography.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Bomb Animation
                  SizedBox(
                    height: (MediaQuery.sizeOf(context).height * .34).clamp(
                      120.0,
                      280.0,
                    ),
                    child: BombAnimationView(
                      tensionRatio: state.tensionRatio,
                      isExploded: state.isExploded,
                    ),
                  ),

                  // Holding indicator badge
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.surfaceBorder,
                        width: 2,
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text('الان بمب دست: ', style: AppTypography.bodyLarge),
                        Text(
                          state.holdingTeamOrPlayer,
                          style: AppTypography.headlineLarge.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Giant Pass Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: PartyButton(
                      label: 'جواب دادم! پاس به بعدی',
                      icon: Icons.send_rounded,
                      height: 64,
                      color: AppColors.bombPrimary,
                      onPressed: () =>
                          context.read<HotPotatoCubit>().passToNext(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplosionResult(BuildContext context, HotPotatoState state) {
    return Scaffold(
      body: AnimatedPartyBackground(
        gameKey: 'hot_potato',
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: PartyCard(
              borderColor: AppColors.bombPrimary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.whatshot_rounded,
                    color: AppColors.bombPrimary,
                    size: 68,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'بوووووم! بمب ترکید!',
                    style: AppTypography.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'بازنده این دور:',
                          style: AppTypography.bodyLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.loserName ?? 'نامشخص',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تعداد کل پاس‌ها در این دور: ${state.turnPassCount} بار',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PartyButton(
                    label: state.isGameOver
                        ? 'نمایش نتیجه'
                        : 'دور جدید با موضوع تازه',
                    icon: state.isGameOver
                        ? Icons.emoji_events_rounded
                        : Icons.refresh_rounded,
                    color: AppColors.primary,
                    onPressed: () {
                      if (state.isGameOver) {
                        context.read<HotPotatoCubit>().showMatchResult();
                      } else {
                        context.read<HotPotatoCubit>().prepareNextRound();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Natural-height controls stay reachable when the topic or text size grows.
class _ScrollableBombStage extends StatelessWidget {
  const _ScrollableBombStage({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      ),
    ),
  );
}
