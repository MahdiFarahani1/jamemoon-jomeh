import 'package:flutter/material.dart';

import '../../app/di/service_locator.dart';
import '../../core/models/game_result.dart';
import '../../core/services/audio_service.dart';
import 'game_emblem.dart';
import 'game_visual_effects.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'animated_party_background.dart';
import 'brand_mark.dart';
import 'confetti_overlay.dart';
import 'party_button.dart';

/// Loads a fresh eligible deck before creating the game and offers retry.
class GameContentGate extends StatefulWidget {
  const GameContentGate({super.key, required this.load, required this.child});
  final Future<void> Function() load;
  final Widget child;

  @override
  State<GameContentGate> createState() => _GameContentGateState();
}

class _GameContentGateState extends State<GameContentGate> {
  late final ValueNotifier<Future<void>> _load = ValueNotifier(widget.load());

  @override
  void dispose() {
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Future<void>>(
    valueListenable: _load,
    builder: (context, future, _) => FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('بسته بازی بارگذاری نشد.'),
                    ElevatedButton(
                      onPressed: () => _load.value = widget.load(),
                      child: const Text('تلاش دوباره'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('بازگشت'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return widget.child;
      },
    ),
  );
}

/// Covers a game on interruption and requires a deliberate tap to resume.
class GameLifecycleGuard extends StatefulWidget {
  const GameLifecycleGuard({
    super.key,
    required this.onPause,
    required this.onResume,
    required this.child,
    this.initiallyCovered = false,
  });

  final VoidCallback onPause;
  final VoidCallback onResume;
  final Widget child;
  final bool initiallyCovered;

  static GameLifecycleGuardState of(BuildContext context) =>
      context.findAncestorStateOfType<GameLifecycleGuardState>()!;

  @override
  State<GameLifecycleGuard> createState() => GameLifecycleGuardState();
}

class GameCompletionView extends StatefulWidget {
  const GameCompletionView({
    super.key,
    required this.gameKey,
    this.result,
    this.onComplete,
    this.onPlayAgain,
  });

  final String gameKey;
  final GameResult? result;
  final VoidCallback? onComplete;
  final VoidCallback? onPlayAgain;

  @override
  State<GameCompletionView> createState() => _GameCompletionViewState();
}

class _GameCompletionViewState extends State<GameCompletionView> {
  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<AudioService>()) sl<AudioService>().playVictory();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Scaffold(
      body: GameResultCelebration(
        gameKey: widget.gameKey,
        child: ConfettiOverlay(
          showConfetti: !MediaQuery.disableAnimationsOf(context),
          child: AnimatedPartyBackground(
            gameKey: widget.gameKey,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: .8, end: 1),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 650),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: const TrophyArt(size: 140),
                        ),
                        const SizedBox(height: 8),
                        GameEmblem(gameKey: widget.gameKey, size: 52),
                        const SizedBox(height: 20),
                        Text(
                          result == null
                              ? 'بازی به پایان رسید!'
                              : result.isTie
                              ? 'بازی مساوی شد!'
                              : 'قهرمان: ${result.winnerName}',
                          style: AppTypography.displayMedium.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (result != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            result.isTie
                                ? 'رقابت شانه به شانه بین ${result.tiedWinnerNames}!'
                                : 'تبریک به ${result.winnerName} برای کسب پیروزی درخشان!',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (result != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.leaderboard_rounded,
                                color: AppColors.accent,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'نتیجهٔ نهایی',
                                style: AppTypography.headlineMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          for (var i = 0; i < result.standings.length; i++)
                            _ResultTeamRow(
                              rank: result.ranks[i],
                              name: result.standings[i].name,
                              score: result.standings[i].score,
                              color: Color(result.standings[i].colorValue),
                              isWinner: result.winners.any(
                                (winner) => winner.id == result.standings[i].id,
                              ),
                            ),
                          if (result.highlights.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Text(
                              'آمار بامزهٔ بازی',
                              style: AppTypography.headlineMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final highlight in result.highlights)
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 210,
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: AppColors.surfaceBorder,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${highlight.emoji} ${highlight.title}',
                                          style: AppTypography.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          highlight.value,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color: AppColors.accent,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                        const SizedBox(height: 28),
                        PartyButton(
                          label: 'ادامه',
                          color: AppColors.accent,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () {
                            widget.onComplete?.call();
                            Navigator.of(context).pop(true);
                          },
                        ),
                        if (widget.onPlayAgain != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: widget.onPlayAgain,
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('شروع دوباره همین بازی'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTeamRow extends StatelessWidget {
  const _ResultTeamRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.color,
    required this.isWinner,
  });

  final int rank;
  final String name;
  final int score;
  final Color color;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };
    final row = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isWinner
            ? Color.lerp(AppColors.surfaceLight, color, .08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWinner ? AppColors.accent : AppColors.surfaceBorder,
          width: isWinner ? 2 : 1,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: .15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWinner
                  ? AppColors.accent.withValues(alpha: .2)
                  : AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              isWinner && rank > 1 ? '🥇' : medal,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (isWinner)
                  Text(
                    'تیم پیروز',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isWinner
                  ? AppColors.accent.withValues(alpha: .16)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score امتیاز',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: isWinner ? AppColors.accent : AppColors.textHeadline,
              ),
            ),
          ),
        ],
      ),
    );
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motionDisabled
          ? Duration.zero
          : Duration(milliseconds: 420 + rank * 110),
      curve: Curves.easeOutBack,
      child: row,
      builder: (context, value, child) {
        final visibleValue = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: visibleValue,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - visibleValue)),
            child: Transform.scale(
              scale: .92 + visibleValue * .08,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class GameLifecycleGuardState extends State<GameLifecycleGuard>
    with WidgetsBindingObserver {
  late final ValueNotifier<bool> _covered = ValueNotifier(
    widget.initiallyCovered,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void cover() {
    if (_covered.value) return;
    widget.onPause();
    _covered.value = true;
  }

  void resume() {
    if (!_covered.value) return;
    _covered.value = false;
    widget.onResume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) cover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _covered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _covered,
    builder: (context, covered, child) => Stack(
      children: [
        ExcludeSemantics(
          excluding: covered,
          child: ExcludeFocus(excluding: covered, child: child!),
        ),
        if (covered)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.pause_rounded,
                              size: 54,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'بازی متوقف شد',
                            style: AppTypography.headlineLarge,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'کلمه‌ها محفوظ‌اند؛ هر وقت آماده بودید ادامه بدید.',
                            style: AppTypography.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          PartyButton(
                            label: 'ادامه بازی',
                            icon: Icons.play_arrow_rounded,
                            onPressed: resume,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('بازگشت به دورهمی'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
    child: widget.child,
  );
}
