import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/game_mode.dart';
import '../../../core/widgets/animated_party_background.dart';
import '../../../core/widgets/how_to_play_sheet.dart';
import '../../../core/widgets/party_button.dart';
import '../../../core/widgets/party_card.dart';

// Home Page with vibrant party cards and quick access (Zero setState)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showGameModeDialog(BuildContext context, GameInfo game) {
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
              Text(game.titleFa, style: AppTypography.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(game.subtitleFa, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              PartyButton(
                label: 'شروع حالت سریع (آزاد)',
                icon: Icons.flash_on_rounded,
                color: AppColors.primary,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamed('/game/${game.key}', arguments: {'isQuickMode': true});
                },
              ),
              const SizedBox(height: 12),
              PartyButton(
                label: 'شروع با تیم‌ها و امتیاز',
                icon: Icons.groups_rounded,
                color: AppColors.surfaceLight,
                textColor: AppColors.textHeadline,
                shadowColor: AppColors.surfaceBorder,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamed('/game/${game.key}', arguments: {'isQuickMode': false});
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.help_outline_rounded, color: AppColors.accent, size: 20),
                label: const Text('آموزش و قوانین این بازی', style: TextStyle(color: AppColors.accent)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  HowToPlaySheet.show(context, game.key);
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
        title: const Text('جمعمون جمعه!'),
        actions: [
          IconButton(
            tooltip: 'فروشگاه',
            icon: const Icon(Icons.shopping_bag_rounded, color: AppColors.accent),
            onPressed: () => Navigator.of(context).pushNamed('/shop'),
          ),
          IconButton(
            tooltip: 'تیم‌ها',
            icon: const Icon(Icons.groups_rounded, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pushNamed('/teams'),
          ),
          IconButton(
            tooltip: 'تنظیمات',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: AnimatedPartyBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 5-Game Tournament Featured Banner
            PartyCard(
              gradient: AppColors.tournamentGradient,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'مسابقه پنجگانه',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'جام بزرگ رقابت در تمام ۵ بازی!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PartyButton(
                    label: 'ورود به جام پنجگانه',
                    icon: Icons.play_arrow_rounded,
                    color: Colors.white,
                    textColor: Colors.black87,
                    shadowColor: Colors.black26,
                    onPressed: () => Navigator.of(context).pushNamed('/tournament'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Title
            const Text('بازی‌های دورهمی', style: AppTypography.headlineLarge),
            const SizedBox(height: 12),

            // 1. Taboo
            _buildGameCard(
              context,
              game: GameInfo.allGames[0],
              gradient: AppColors.tabooGradient,
              icon: Icons.chat_bubble_rounded,
            ),
            const SizedBox(height: 14),

            // 2. Hot Potato
            _buildGameCard(
              context,
              game: GameInfo.allGames[1],
              gradient: AppColors.bombGradient,
              icon: Icons.timer_rounded,
            ),
            const SizedBox(height: 14),

            // 3. Charades
            _buildGameCard(
              context,
              game: GameInfo.allGames[2],
              gradient: AppColors.charadesGradient,
              icon: Icons.theater_comedy_rounded,
            ),
            const SizedBox(height: 14),

            // 4. 5-Second Rule
            _buildGameCard(
              context,
              game: GameInfo.allGames[3],
              gradient: AppColors.fiveSecGradient,
              icon: Icons.flash_on_rounded,
            ),
            const SizedBox(height: 14),

            // 5. Drawing
            _buildGameCard(
              context,
              game: GameInfo.allGames[4],
              gradient: AppColors.drawGradient,
              icon: Icons.brush_rounded,
            ),
            const SizedBox(height: 24),

            // Extra Fun Features
            const Text('امکانات ویژه دورهمی', style: AppTypography.headlineLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PartyCard(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    onTap: () => Navigator.of(context).pushNamed('/extras/wheel'),
                    child: const Column(
                      children: [
                        Icon(Icons.toys_rounded, color: AppColors.accent, size: 36),
                        SizedBox(height: 8),
                        Text('گردونه شانس', style: AppTypography.titleLarge, textAlign: TextAlign.center),
                        SizedBox(height: 4),
                        Text('چالش‌های بامزه', style: AppTypography.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PartyCard(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    onTap: () => Navigator.of(context).pushNamed('/extras/picker'),
                    child: const Column(
                      children: [
                        Icon(Icons.shuffle_rounded, color: AppColors.primary, size: 36),
                        SizedBox(height: 8),
                        Text('انتخاب تصادفی', style: AppTypography.titleLarge, textAlign: TextAlign.center),
                        SizedBox(height: 4),
                        Text('قرعه‌کشی نوبت', style: AppTypography.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PartyCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              onTap: () => Navigator.of(context).pushNamed('/extras/custom-cards'),
              child: const Row(
                children: [
                  Icon(Icons.add_to_photos_rounded, color: AppColors.success, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('کارت‌ساز اختصاصی', style: AppTypography.headlineMedium),
                        Text('کلمات و شوخی‌های خانوادگی خودتان را اضافه کنید', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: AppColors.textParagraph),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required GameInfo game,
    required LinearGradient gradient,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showGameModeDialog(context, game),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.titleFa,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.subtitleFa,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

