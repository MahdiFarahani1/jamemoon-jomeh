import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../cubit/extras_cubit.dart';

class LuckyWheelPage extends StatelessWidget {
  const LuckyWheelPage({super.key});
  static const segments = [
    'امتیاز دو برابر',
    'زمان نصف شد',
    'تعویض اجراکننده',
    'سکوت کامل جمع',
    'چالش با دست چپ',
    'شادی و هورا',
    'کسر یک امتیاز',
    'شانس مجدد',
  ];
  static const colors = [
    Color(0xFFFF786B),
    Color(0xFFEAAF62),
    Color(0xFFD6C277),
    Color(0xFF79C7A3),
    Color(0xFF68BDCC),
    Color(0xFF818FDC),
    Color(0xFFB18ED7),
    Color(0xFFE293AF),
  ];
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WheelCubit(),
    child: Scaffold(
      appBar: AppBar(title: const Text('گردونه شانس')),
      body: AnimatedPartyBackground(
        child: SafeArea(
          top: false,
          child: BlocBuilder<WheelCubit, WheelState>(
            builder: (context, state) => LayoutBuilder(
              builder: (context, constraints) {
                final size = (constraints.maxWidth - 80).clamp(160.0, 320.0);
                final reducedMotion = MediaQuery.disableAnimationsOf(context);
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'یه چالش تازه!',
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'گردونه رو بچرخون و قانون این دور رو ببین.',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        state.selected == null
                            ? 'آماده چرخوندنی؟'
                            : segments[state.selected!],
                        style: AppTypography.headlineLarge.copyWith(
                          color: AppColors.accent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: SizedBox.square(
                        dimension: size + 12,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(end: state.rotation),
                              duration: reducedMotion
                                  ? Duration.zero
                                  : const Duration(seconds: 3),
                              curve: Curves.easeOutCubic,
                              builder: (_, angle, child) =>
                                  Transform.rotate(angle: angle, child: child),
                              child: CustomPaint(
                                size: Size.square(size),
                                painter: _WheelPainter(),
                              ),
                            ),
                            const CircleAvatar(
                              backgroundColor: AppColors.surface,
                              radius: 23,
                              child: Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                            const Positioned(
                              top: 0,
                              child: Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 46,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PartyButton(
                      label: state.busy ? 'در حال چرخش...' : 'بچرخون!',
                      icon: Icons.refresh_rounded,
                      onPressed: state.busy
                          ? null
                          : () => context.read<WheelCubit>().spin(
                              segments.length,
                              reducedMotion: reducedMotion,
                            ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < segments.length; i++)
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: colors[i],
                              radius: 7,
                            ),
                            label: Text(segments[i]),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweep = 2 * pi / LuckyWheelPage.segments.length;
    for (var i = 0; i < LuckyWheelPage.segments.length; i++) {
      canvas.drawArc(
        rect,
        -pi / 2 + i * sweep,
        sweep,
        true,
        Paint()..color = LuckyWheelPage.colors[i],
      );
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2,
      Paint()
        ..color = AppColors.surfaceBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
