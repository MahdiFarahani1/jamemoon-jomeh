import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';

// Lucky Wheel with Special Modifiers (Zero setState)
class LuckyWheelPage extends StatelessWidget {
  const LuckyWheelPage({super.key});

  static const List<String> segments = [
    'امتیاز ۲ برابر! ⭐',
    'زمان نصف شد! ⏱️',
    'تعویض اجراکننده 🔄',
    'سکوت کامل جمع 🤫',
    'چالش با دست چپ ✋',
    'شادی و هورا! 🥳',
    'کسر ۱ امتیاز! 💥',
    'شانس مجدد 🎲',
  ];

  @override
  Widget build(BuildContext context) {
    final rotationNotifier = ValueNotifier<double>(0.0);
    final selectedResultNotifier = ValueNotifier<String?>(null);
    final isSpinningNotifier = ValueNotifier<bool>(false);
    final random = Random();

    return Scaffold(
      appBar: AppBar(
        title: const Text('گردونه شانس و چالش‌ها'),
      ),
      body: AnimatedPartyBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const Text('گردونه رو بچرخون تا قانون ویژه این دور مشخص بشه!', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Result Display
              ValueListenableBuilder<String?>(
                valueListenable: selectedResultNotifier,
                builder: (context, result, _) {
                  if (result == null) {
                    return Container(
                      height: 64,
                      alignment: Alignment.center,
                      child: Text('دکمه چرخاندن را بزنید!', style: AppTypography.titleLarge.copyWith(color: AppColors.accent)),
                    );
                  }
                  return Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        result,
                        style: AppTypography.headlineLarge.copyWith(color: AppColors.accent),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Rotating Wheel
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Rotating Wheel
                      ValueListenableBuilder<double>(
                        valueListenable: rotationNotifier,
                        builder: (context, angle, _) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: angle),
                            duration: const Duration(seconds: 3),
                            curve: Curves.easeOutCubic,
                            builder: (context, currentAngle, child) {
                              return Transform.rotate(
                                angle: currentAngle,
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.surfaceBorder, width: 6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.35),
                                        blurRadius: 28,
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    painter: _WheelPainter(segments: segments),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Center Pin
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.accent, width: 3),
                        ),
                        child: const Icon(Icons.star_rounded, color: AppColors.accent, size: 24),
                      ),
                      // Top Indicator Arrow
                      Positioned(
                        top: 2,
                        child: Container(
                          width: 24,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Spin Button
              ValueListenableBuilder<bool>(
                valueListenable: isSpinningNotifier,
                builder: (context, isSpinning, _) {
                  return PartyButton(
                    label: isSpinning ? 'در حال چرخش...' : 'بچرخون!',
                    icon: Icons.refresh_rounded,
                    color: AppColors.primary,
                    onPressed: isSpinning
                        ? null
                        : () async {
                            isSpinningNotifier.value = true;
                            sl<HapticsService>().mediumBump();
                            sl<AudioService>().playTick();

                            // Pick random segment
                            final selectedIndex = random.nextInt(segments.length);
                            final spins = 5 + random.nextInt(4);
                            final segmentAngle = (2 * pi) / segments.length;
                            final targetAngle = rotationNotifier.value + (spins * 2 * pi) + (selectedIndex * segmentAngle);

                            rotationNotifier.value = targetAngle;

                            // Wait for wheel animation
                            await Future.delayed(const Duration(seconds: 3));
                            selectedResultNotifier.value = segments[selectedIndex];
                            sl<AudioService>().playVictory();
                            sl<HapticsService>().lightClick();
                            isSpinningNotifier.value = false;
                          },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> segments;
  _WheelPainter({required this.segments});

  static const List<Color> colors = [
    Color(0xFFFF5252),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF00BCD4),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
