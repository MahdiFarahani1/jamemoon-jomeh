import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/di/service_locator.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../services/audio_service.dart';
import 'animated_party_background.dart';
import 'brand_mark.dart';
import 'game_emblem.dart';
import 'party_button.dart';

/// Privacy handoff followed by a deliberate, cancellable three-second count-in.
class PassPhoneOverlay extends StatefulWidget {
  const PassPhoneOverlay({
    super.key,
    required this.teamName,
    this.playerName,
    this.partnerName,
    required this.gameTitle,
    required this.onReady,
  });
  final String teamName;
  final String? playerName;
  final String? partnerName;
  final String gameTitle;
  final VoidCallback onReady;
  @override
  State<PassPhoneOverlay> createState() => _PassPhoneOverlayState();
}

class _PassPhoneOverlayState extends State<PassPhoneOverlay>
    with WidgetsBindingObserver {
  final _count = ValueNotifier<int?>(null);
  final _stage = ValueNotifier<int>(0);
  Timer? _timer;
  Timer? _drawTimer;
  String get _gameKey {
    final title = widget.gameTitle;
    if (title.contains('بمب')) return 'hot_potato';
    if (title.contains('پانتومیم')) return 'charades';
    if (title.contains('سه‌تا') || title.contains('ثانیه')) {
      return 'five_seconds';
    }
    if (title.contains('نقاشی')) return 'drawing';
    return 'taboo';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _cancelCountdown() {
    _timer?.cancel();
    _timer = null;
    _count.value = null;
    _stage.value = 2;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _timer?.cancel();
      _drawTimer?.cancel();
      _count.value = null;
      _stage.value = _stage.value == 1 ? 0 : 2;
    }
  }

  void _tick() {
    if (sl.isRegistered<AudioService>()) {
      sl<AudioService>().playStart();
    }
  }

  void _drawStarter() {
    if (_stage.value != 0) return;
    _stage.value = 1;
    if (sl.isRegistered<AudioService>()) {
      sl<AudioService>().playReveal();
    }
    _drawTimer = Timer(
      MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 50)
          : const Duration(milliseconds: 1200),
      () {
        if (!mounted) return;
        _stage.value = 2;
        if (sl.isRegistered<AudioService>()) {
          sl<AudioService>().playTurn();
        }
      },
    );
  }

  void _startCountdown() {
    if (_stage.value != 2 || _count.value != null) return;
    _stage.value = 3;
    _count.value = 3;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _count.value! - 1;
      if (next == 0) {
        _timer?.cancel();
        _timer = null;
        _count.value = null;
        widget.onReady();
      } else {
        _count.value = next;
        _tick();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _drawTimer?.cancel();
    _count.dispose();
    _stage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.gameAccent(_gameKey);
    return AnimatedPartyBackground(
      gameKey: _gameKey,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: PartyEntrance(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_count, _stage]),
                  builder: (context, _) {
                    final count = _count.value;
                    final stage = _stage.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.gameTitle,
                              style: AppTypography.bodyMedium.copyWith(
                                color: accent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 160,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                              child: stage == 1
                                  ? TweenAnimationBuilder<double>(
                                      key: const ValueKey('starter-draw'),
                                      tween: Tween(begin: 0, end: 4),
                                      duration:
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          )
                                          ? Duration.zero
                                          : const Duration(milliseconds: 1200),
                                      builder: (context, turns, _) =>
                                          Transform.rotate(
                                            angle: turns * 3.141592653589793,
                                            child: Icon(
                                              Icons.shuffle_rounded,
                                              color: accent,
                                              size: 104,
                                            ),
                                          ),
                                    )
                                  : stage != 3
                                  ? GameEmblem(
                                      key: const ValueKey('art'),
                                      gameKey: _gameKey,
                                      size: 152,
                                    )
                                  : Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        '$count',
                                        key: ValueKey(count),
                                        style: AppTypography.timerDigits
                                            .copyWith(
                                              fontSize: 100,
                                              color: accent,
                                            ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          switch (stage) {
                            0 => 'شروع‌کننده رو قرعه بکشیم!',
                            1 => 'داریم قرعه می‌کشیم…',
                            2 => 'شروع با:',
                            _ => 'آماده، با تمرکز، بریم!',
                          },
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (stage >= 2)
                          Text(
                            widget.teamName,
                            style: AppTypography.headlineLarge.copyWith(
                              color: accent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (stage >= 2 && widget.playerName != null)
                          Text(
                            'نوبت اجرا: ${widget.playerName}',
                            style: AppTypography.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        if (stage >= 2 && widget.partnerName != null)
                          Text(
                            '${widget.playerName} برای ${widget.partnerName} اجرا می‌کند',
                            style: AppTypography.bodyLarge.copyWith(
                              color: accent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                color: AppColors.textMuted,
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'گوشی رو به بازیکن بعدی بده. فقط کسی که نوبتشه باید صفحه رو ببینه!',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        PartyButton(
                          label: switch (stage) {
                            0 => 'قرعه شروع',
                            1 => 'در حال قرعه…',
                            2 => 'گوشی دستمه، شروع شمارش',
                            _ => 'شروع تا $count ثانیه…',
                          },
                          icon: switch (stage) {
                            0 => Icons.shuffle_rounded,
                            1 => Icons.hourglass_top_rounded,
                            2 => Icons.phone_android_rounded,
                            _ => Icons.timer_outlined,
                          },
                          color: accent,
                          onPressed: switch (stage) {
                            0 => _drawStarter,
                            2 => _startCountdown,
                            _ => null,
                          },
                        ),
                        const SizedBox(height: 12),
                        if (stage == 3)
                          TextButton(
                            onPressed: _cancelCountdown,
                            child: const Text('یه لحظه، هنوز آماده نیستم'),
                          )
                        else if (stage == 0)
                          const Text(
                            'انتخاب شروع‌کننده این بار کاملاً تصادفیه',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
