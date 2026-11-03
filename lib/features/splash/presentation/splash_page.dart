import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/widgets/animated_party_background.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/party_button.dart';
import '../../taboo/data/taboo_repository.dart';
import '../../hot_potato/data/hot_potato_repository.dart';
import '../../charades/data/charades_repository.dart';
import '../../five_seconds/data/five_seconds_repository.dart';
import '../../drawing/data/drawing_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final ValueNotifier<bool> _failed = ValueNotifier(false);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _failed.value = false;
    try {
      await Future.wait([
        sl<TabooRepository>().loadCards(),
        sl<HotPotatoRepository>().loadTopics(),
        sl<CharadesRepository>().loadWords(),
        sl<FiveSecondsRepository>().loadQuestions(),
        sl<DrawingRepository>().loadWords(),
      ]);
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
      if (mounted) _failed.value = true;
    }
  }

  @override
  void dispose() {
    _failed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedPartyBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 132),
                  const SizedBox(height: 20),
                  const Text(
                    'جمعمون جمعه!',
                    style: AppTypography.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'بازی و خنده، کنار هم',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  ValueListenableBuilder<bool>(
                    valueListenable: _failed,
                    builder: (context, failed, _) => failed
                        ? Column(
                            children: [
                              const Text(
                                'بارگذاری بازی‌ها انجام نشد. دوباره تلاش کنید.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              PartyButton(
                                label: 'تلاش دوباره',
                                icon: Icons.refresh_rounded,
                                onPressed: _load,
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
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
