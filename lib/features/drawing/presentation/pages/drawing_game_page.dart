import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/app/theme/app_typography.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/core/widgets/custom_timer_widget.dart';
import 'package:flutter_application_1/core/widgets/how_to_play_sheet.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_card.dart';
import 'package:flutter_application_1/core/widgets/party_dialog.dart';
import 'package:flutter_application_1/core/widgets/pass_phone_overlay.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import '../cubit/drawing_cubit.dart';
import '../cubit/drawing_state.dart';
import '../../data/drawing_repository.dart';
import '../widgets/drawing_canvas_view.dart';
import '../widgets/palette_toolbar.dart';

// Drawing Game Page (Zero setState)
class DrawingGamePage extends StatelessWidget {
  final bool isQuickMode;

  const DrawingGamePage({super.key, this.isQuickMode = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DrawingCubit(
        repository: sl<DrawingRepository>(),
        isQuickMode: isQuickMode,
        teamsCubit: isQuickMode ? null : context.read<TeamsCubit>(),
      ),
      child: const _DrawingGameView(),
    );
  }
}

class _DrawingGameView extends StatelessWidget {
  const _DrawingGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, state) {
        if (state.isPassPhonePhase) {
          return Scaffold(
            body: PassPhoneOverlay(
              teamName: state.activeTeamName,
              gameTitle: 'نقاشی افتضاح!',
              onReady: () => context.read<DrawingCubit>().prepareWord(),
            ),
          );
        }

        // Secret Word Reveal exclusively for the Drawer
        if (state.isWordRevealed) {
          return Scaffold(
            body: AnimatedPartyBackground(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PartyCard(
                    borderColor: AppColors.drawPrimary,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.brush_rounded, color: AppColors.drawPrimary, size: 54),
                        const SizedBox(height: 12),
                        const Text('کلمه اختصاصی نقاش', style: AppTypography.headlineLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          'بقیه بازیکن‌ها این صفحه رو نبینن!',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.accent),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.drawPrimary.withOpacity(0.4)),
                          ),
                          child: Text(
                            state.currentWord?.word ?? 'در حال آماده‌سازی...',
                            style: AppTypography.displayMedium.copyWith(color: AppColors.drawPrimary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PartyButton(
                          label: 'آماده‌ام، بریم روی بوم!',
                          icon: Icons.palette_rounded,
                          color: AppColors.drawPrimary,
                          onPressed: () => context.read<DrawingCubit>().startDrawingOnCanvas(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (state.isRoundOver) {
          return _buildRoundSummary(context, state);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(state.activeTeamName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                final confirm = await PartyDialog.show(
                  context,
                  title: 'خروج از نقاشی',
                  message: 'آیا می‌خواهید از بازی نقاشی خارج شوید؟',
                  confirmLabel: 'بله، خروج',
                );
                if (confirm == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              IconButton(
                tooltip: 'راهنمای بازی',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => HowToPlaySheet.show(context, 'drawing'),
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Header Bar with Timer and Correct Guess Button
                    Row(
                      children: [
                        CustomTimerWidget(
                          remainingSeconds: state.remainingSeconds,
                          totalSeconds: state.totalSeconds,
                          size: 58,
                          activeColor: AppColors.drawPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PartyButton(
                            label: 'حدس درست زدند! (+۲)',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            height: 48,
                            onPressed: () => context.read<DrawingCubit>().onCorrectGuess(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Drawing Canvas
                    Expanded(
                      child: DrawingCanvasView(
                        completedStrokes: state.strokes,
                        activeColor: state.activeColor,
                        strokeWidth: state.strokeWidth,
                        isEraser: state.isEraser,
                        onStrokeFinished: (stroke) {
                          context.read<DrawingCubit>().addStroke(stroke);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Palette and Tools
                    PaletteToolbar(
                      activeColor: state.activeColor,
                      strokeWidth: state.strokeWidth,
                      isEraser: state.isEraser,
                      onColorChanged: (c) => context.read<DrawingCubit>().setColor(c),
                      onStrokeWidthChanged: (w) => context.read<DrawingCubit>().setStrokeWidth(w),
                      onToggleEraser: () => context.read<DrawingCubit>().toggleEraser(),
                      onUndo: () => context.read<DrawingCubit>().undo(),
                      onClear: () => context.read<DrawingCubit>().clearCanvas(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoundSummary(BuildContext context, DrawingState state) {
    final word = state.currentWord?.word ?? '';
    final won = state.roundScore > 0;

    return Scaffold(
      body: AnimatedPartyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PartyCard(
              borderColor: AppColors.drawPrimary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    won ? Icons.emoji_events_rounded : Icons.alarm_off_rounded,
                    color: won ? AppColors.accent : AppColors.error,
                    size: 58,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    won ? 'آفرین! حدس درست بود!' : 'زمان نقاشی تموم شد!',
                    style: AppTypography.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text('کلمه مخفی این دور:', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text(word, style: AppTypography.headlineLarge.copyWith(color: AppColors.accent)),
                        const Divider(color: AppColors.surfaceBorder, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('امتیاز کسب شده:', style: AppTypography.bodyLarge),
                            Text(
                              '+${state.roundScore}',
                              style: AppTypography.headlineLarge.copyWith(
                                color: won ? AppColors.success : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PartyButton(
                    label: 'نوبت تیم بعدی',
                    icon: Icons.arrow_forward_rounded,
                    color: AppColors.drawPrimary,
                    onPressed: () => context.read<DrawingCubit>().nextTurn(),
                  ),
                  const SizedBox(height: 10),
                  PartyButton(
                    label: 'خروج به منوی اصلی',
                    color: AppColors.surfaceLight,
                    textColor: AppColors.textHeadline,
                    shadowColor: AppColors.surfaceBorder,
                    onPressed: () => Navigator.of(context).pop(),
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
