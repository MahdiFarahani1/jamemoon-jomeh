import 'package:flutter/material.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/game_mode.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/animated_party_background.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/game_emblem.dart';
import '../../../core/widgets/party_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _revision = ValueNotifier(0);
  @override
  void dispose() {
    _revision.dispose();
    super.dispose();
  }

  Future<void> _go(String route, {Object? arguments}) async {
    await Navigator.of(context).pushNamed(route, arguments: arguments);
    if (mounted) _revision.value++;
  }

  void _openGame(GameInfo game) {
    if (game.key == 'heist' && !sl<StorageService>().isPackPurchased('heist')) {
      _showHeistLockedDialog();
      return;
    }
    _go('/prepare/${game.key}');
  }

  void _showHeistLockedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.accent, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'بازی «سرقت بزرگ» (ویژه اشتراک)',
                style: AppTypography.headlineMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بازی «سرقت بزرگ» و بیش از ۲٬۰۰۰ کلمه و کارت جدید در اشتراک طلایی جمعمون جمعه قرار دارند.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⭐ باز شدن کامل بازی استراتژیک سرقت بزرگ', style: AppTypography.bodySmall),
                  SizedBox(height: 4),
                  Text('⭐ ۲۰۰۰ کارت و موضوع جدید در تمام بازی‌ها', style: AppTypography.bodySmall),
                  SizedBox(height: 4),
                  Text('⭐ دسترسی دائمی بدون محدودیت و کاملاً آفلاین', style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'قیمت اشتراک: ۹۹٬۰۰۰ تومان',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('فعلاً نه'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _go('/shop');
            },
            child: const Text('مشاهده و خرید اشتراک'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: _revision,
    builder: (context, _, _) {
      final storage = sl<StorageService>();
      final saved = GameInfo.allGames
          .where((g) => storage.getGameSession(g.key) != null)
          .toList();
      final tournament = storage.getActiveTournament();
      final active = tournament != null && tournament['isFinished'] != true;
      return Scaffold(
        body: AnimatedPartyBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: PartyEntrance(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const BrandMark(size: 54),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'جمعمون جمعه!',
                                          style: AppTypography.headlineMedium,
                                        ),
                                        Text(
                                          'یه جمع، کلی خاطره',
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _RoundAction(
                                    icon: Icons.settings_outlined,
                                    label: 'تنظیمات',
                                    onTap: () => _go('/settings'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'امشب چی بازی کنیم؟',
                                style: AppTypography.displayMedium,
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'گوشی رو بردار، جمع رو گرم کن!',
                                style: AppTypography.bodyLarge,
                              ),
                              const SizedBox(height: 22),
                              _TournamentHero(
                                active: active,
                                onTap: () => _go('/tournament'),
                              ),
                              const SizedBox(height: 14),
                              _ChallengeInvitation(
                                onTap: () => _go('/extras/challenges'),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _Shortcut(
                                      icon: Icons.groups_2_outlined,
                                      label: 'تیم‌های ما',
                                      color: AppColors.primary,
                                      onTap: () => _go('/teams'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _Shortcut(
                                      icon: Icons.stars_rounded,
                                      label: 'اشتراک طلایی',
                                      color: AppColors.accent,
                                      onTap: () => _go('/shop'),
                                    ),
                                  ),
                                ],
                              ),
                              if (saved.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                const Text(
                                  'دورهمی هنوز ادامه داره',
                                  style: AppTypography.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final game in saved)
                                      ActionChip(
                                        avatar: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 18,
                                        ),
                                        label: Text('ادامه ${game.titleFa}'),
                                        onPressed: () => _go(
                                          '/game/${game.key}',
                                          arguments: {'resume': true},
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'یک بازی، کلی خنده',
                                      style: AppTypography.headlineMedium,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${GameInfo.allGames.length} بازی',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final scale =
                              MediaQuery.textScalerOf(context).scale(14) / 14;
                          final columns = scale > 1.35
                              ? (width >= 680 ? 2 : 1)
                              : (width >= 680 ? 3 : 2);
                          final tileWidth =
                              (width - (columns - 1) * 12) / columns;
                          // More space at large text settings; each card remains fully readable.
                          final height =
                              230 +
                              (scale - 1).clamp(0, 2) * 150 +
                              (tileWidth < 160 ? 28 : 0);
                          return SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: height.toDouble(),
                                ),
                            itemCount: GameInfo.allGames.length,
                            itemBuilder: (context, index) => _GameTile(
                              game: GameInfo.allGames[index],
                              onTap: () => _openGame(GameInfo.allGames[index]),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'چاشنیِ دورهمی',
                              style: AppTypography.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'برای وقتی که انتخاب سخت می‌شه!',
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            _ExtraRow(
                              label: 'قرعه‌کشی',
                              subtitle: 'نوبت کیه شام رو حساب کنه؟',
                              icon: Icons.shuffle_rounded,
                              color: AppColors.primary,
                              onTap: () => _go('/extras/picker'),
                            ),
                            const SizedBox(height: 10),
                            _ExtraRow(
                              label: 'کارت‌های من',
                              subtitle: 'شوخی‌ها و کلمه‌های مخصوص جمع شما',
                              icon: Icons.style_outlined,
                              color: AppColors.success,
                              onTap: () => _go('/extras/custom-cards'),
                            ),
                            const SizedBox(height: 28),
                            const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite_rounded,
                                    size: 14,
                                    color: AppColors.tabooPrimary,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'خوشی یعنی همین کنار هم بودن',
                                      style: AppTypography.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TournamentHero extends StatelessWidget {
  const _TournamentHero({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF272C47),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF444969)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'یه رقابت تمام‌عیار',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('جام دورهمی', style: AppTypography.headlineLarge),
            const SizedBox(height: 5),
            const Text(
              'پنج بازی، یک تیم قهرمان!',
              style: AppTypography.bodyMedium,
            ),
          ],
        );
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    const TrophyArt(size: 118),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    const TrophyArt(size: 148),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              PartyButton(
                label: active ? 'ادامهٔ جام' : 'بزن بریم برای جام!',
                icon: Icons.emoji_events_outlined,
                color: AppColors.accent,
                onPressed: onTap,
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.onTap});
  final GameInfo game;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isLocked = game.key == 'heist' &&
        !sl<StorageService>().isPackPurchased('heist');
    final color = isLocked ? AppColors.accent : AppColors.gameAccent(game.key);
    final tag = switch (game.key) {
      'taboo' => 'کلمه‌بازی',
      'hot_potato' => 'پر از هیجان',
      'charades' => 'بی‌کلام',
      'five_seconds' => 'سرعتی',
      'drawing' => 'خلاقانه',
      'decoder' => 'معمایی',
      'heist' => 'استراتژیک و مخفی',
      _ => 'دورهمی',
    };
    final title = switch (game.key) {
      'taboo' => 'تابو',
      'hot_potato' => 'بمب دست کیه؟',
      'charades' => 'پانتومیم',
      'five_seconds' => 'سه‌تا بگو!',
      'drawing' => 'نقاشی افتضاح!',
      'decoder' => 'رمزگشا',
      'heist' => 'سرقت بزرگ',
      _ => game.titleFa,
    };
    final subtitle = switch (game.key) {
      'taboo' => 'بگو، ولی نه هر کلمه‌ای!',
      'hot_potato' => 'پاس بده، قبل از انفجار!',
      'charades' => 'با حرکتت حرف بزن!',
      'five_seconds' => '۳ جواب، فقط ۵ ثانیه',
      'drawing' => 'بکش، بخند، حدس بزن!',
      'decoder' => 'سرنخ بده، راز رو کشف کن',
      'heist' => 'نقشه بکش، خیانت کن، غنیمت ببر!',
      _ => game.subtitleFa,
    };
    return Semantics(
      button: true,
      onTap: onTap,
      label: '${game.titleFa}، ${game.subtitleFa}',
      excludeSemantics: true,
      child: Material(
        color: Color.lerp(AppColors.surface, color, .035),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: .2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLocked) ...[
                      const Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'ویژه اشتراک',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          tag,
                          style: AppTypography.bodySmall.copyWith(
                            color: color,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest.shortestSide.clamp(
                        56.0,
                        104.0,
                      );
                      return Center(
                        child: GameEmblem(gameKey: game.key, size: size),
                      );
                    },
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLocked ? 'باز کردن با اشتراک' : 'بازی کنیم',
                        style: AppTypography.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      isLocked
                          ? Icons.lock_open_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onTap,
    icon: Icon(icon, size: 23),
    style: IconButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textParagraph,
      minimumSize: const Size(48, 48),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHeadline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.titleLarge),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChallengeInvitation extends StatelessWidget {
  const _ChallengeInvitation({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'چالش جمع، ۲۴ کارت غافلگیرکننده برای دورهمی',
    onTap: onTap,
    child: ExcludeSemantics(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF393154), Color(0xFF272B43)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.charadesPrimary.withValues(alpha: .25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.charadesPrimary.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.charadesPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('چالش جمع', style: AppTypography.titleLarge),
                      SizedBox(height: 4),
                      Text(
                        'یه کارت غافلگیرکننده؛ کلی خنده!',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.charadesPrimary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
