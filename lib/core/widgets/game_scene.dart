import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class GameSceneRibbon extends StatelessWidget implements PreferredSizeWidget {
  const GameSceneRibbon({super.key, required this.gameKey});
  final String gameKey;
  @override
  Size get preferredSize => const Size.fromHeight(38);
  @override
  Widget build(BuildContext context) {
    final (title, icon) = switch (gameKey) {
      'taboo' => (
        'باشگاه کلمه‌ها · دورِ کلمه‌های ممنوعه بگرد!',
        Icons.forum_rounded,
      ),
      'charades' => (
        'روی صحنه‌ای! · ستارهٔ این اجرا تویی',
        Icons.auto_awesome_rounded,
      ),
      'hot_potato' => ('منطقهٔ خطر · جواب بده و پاس بده!', Icons.bolt_rounded),
      'five_seconds' => ('مسیر سرعت · سه جواب، یک نفس!', Icons.speed_rounded),
      'drawing' => ('آتلیهٔ جمع · هر خطت یه سرنخه!', Icons.gesture_rounded),
      _ => ('اتاق رمز · هر کلمه یک قدم به کشف راز', Icons.hub_rounded),
    };
    final color = AppColors.gameAccent(gameKey);
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .14), color.withValues(alpha: .03)],
        ),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: .2))),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                title,
                style: AppTypography.bodySmall.copyWith(color: color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .4 + i * .2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Visual reward only: never changes points, time or stored game state.
class ScoreBurst extends StatefulWidget {
  const ScoreBurst({
    super.key,
    required this.score,
    required this.roundKey,
    required this.child,
  });
  final int score;
  final Object roundKey;
  final Widget child;
  @override
  State<ScoreBurst> createState() => _ScoreBurstState();
}

class _ScoreBurstState extends State<ScoreBurst> {
  final Queue<int> _pending = Queue<int>();
  final ValueNotifier<int> _revision = ValueNotifier(0);
  Timer? _displayTimer;
  int _delta = 0, _generation = 0;

  @override
  void didUpdateWidget(covariant ScoreBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roundKey != widget.roundKey) {
      _pending.clear();
      _displayTimer?.cancel();
      _delta = 0;
      return;
    }
    final change = widget.score - oldWidget.score;
    if (change != 0) {
      _pending.add(change);
      if (_delta == 0) {
        _delta = _pending.removeFirst();
        _displayTimer = Timer(const Duration(milliseconds: 900), _advance);
        _generation++;
      }
    }
  }

  void _advance() {
    if (!mounted) return;
    _delta = _pending.isEmpty ? 0 : _pending.removeFirst();
    _generation++;
    _revision.value++;
    if (_delta != 0) {
      _displayTimer = Timer(const Duration(milliseconds: 900), _advance);
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _revision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: _revision,
    builder: (context, _, _) => Stack(
      children: [
        widget.child,
        if (_delta != 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -.78),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_generation),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, _) {
                    if (value >= 1) return const SizedBox.shrink();
                    final reduced = MediaQuery.disableAnimationsOf(context);
                    final opacity = reduced
                        ? 1.0
                        : value < .15
                        ? (value / .15).clamp(0.0, 1.0)
                        : value > .75
                        ? ((1 - value) / .25).clamp(0.0, 1.0)
                        : 1.0;
                    final slideOffset = reduced
                        ? 0.0
                        : value < .2
                        ? -16 * (1 - (value / .2))
                        : -14 * (value - .2);
                    final scale = reduced
                        ? 1.0
                        : value < .2
                        ? .85 + .2 * math.sin((value / .2) * math.pi / 2)
                        : 1.0;
                    final isNegative = _delta < 0;
                    final bgColor = isNegative
                        ? AppColors.error
                        : AppColors.success;
                    final gradient = isNegative
                        ? const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          );
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, slideOffset),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isNegative
                                              ? const Color(0xFFB71C1C)
                                              : const Color(0xFF1B5E20))
                                          .withValues(alpha: .45),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isNegative
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isNegative
                                        ? 'تخلف!  $_delta'
                                        : 'آفرین!  +$_delta',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .5,
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
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
