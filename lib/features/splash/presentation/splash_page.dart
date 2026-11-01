import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/widgets/animated_party_background.dart';
import '../../taboo/data/taboo_repository.dart';
import '../../hot_potato/data/hot_potato_repository.dart';
import '../../charades/data/charades_repository.dart';
import '../../five_seconds/data/five_seconds_repository.dart';
import '../../drawing/data/drawing_repository.dart';

// Splash Screen with bouncy party logo & async assets loading (Zero setState)
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  Future<void> _loadAssetsAndNavigate(BuildContext context) async {
    // Load all JSON decks in parallel
    await Future.wait([
      sl<TabooRepository>().loadCards(),
      sl<HotPotatoRepository>().loadTopics(),
      sl<CharadesRepository>().loadWords(),
      sl<FiveSecondsRepository>().loadQuestions(),
      sl<DrawingRepository>().loadWords(),
      Future.delayed(const Duration(milliseconds: 1200)), // Smooth branded delay
    ]);

    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger load on render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssetsAndNavigate(context);
    });

    return Scaffold(
      body: AnimatedPartyBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo badge with glow
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.purpleGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 35,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.celebration_rounded,
                          size: 72,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'جمعمون جمعه!',
                style: AppTypography.displayLarge,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'بازی دورهمی پرانرژی و خنده‌دار ایرانی',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
