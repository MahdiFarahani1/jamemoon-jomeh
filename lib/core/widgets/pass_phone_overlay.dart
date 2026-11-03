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
    required this.gameTitle,
    required this.onReady,
  });
  final String teamName;
  final String? playerName;
  final String gameTitle;
  final VoidCallback onReady;
  @override
  State<PassPhoneOverlay> createState() => _PassPhoneOverlayState();
}

class _PassPhoneOverlayState extends State<PassPhoneOverlay>
    with WidgetsBindingObserver {
  final _count = ValueNotifier<int?>(null);
  Timer? _timer;
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

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _count.value = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cancel();
    }
  }

  void _tick() {
    if (sl.isRegistered<AudioService>()) {
      sl<AudioService>().playTick();
    }
  }

  void _start() {
    if (_count.value != null) return;
    _count.value = 3;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _count.value! - 1;
      if (next == 0) {
        _cancel();
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
    _count.dispose();
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
                child: ValueListenableBuilder<int?>(
                  valueListenable: _count,
                  builder: (context, count, _) => Column(
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
                            child: count == null
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
                                      style: AppTypography.timerDigits.copyWith(
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
                        count == null
                            ? 'نوبتِ شماست!'
                            : 'آماده، با تمرکز، بریم!',
                        style: AppTypography.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.teamName,
                        style: AppTypography.headlineLarge.copyWith(
                          color: accent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.playerName != null)
                        Text(
                          'نوبت اجرا: ${widget.playerName}',
                          style: AppTypography.bodyLarge,
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
                        label: count == null
                            ? 'آماده‌ام، شروع کن!'
                            : 'شروع تا $count ثانیه…',
                        icon: count == null
                            ? Icons.play_arrow_rounded
                            : Icons.hourglass_top_rounded,
                        color: accent,
                        onPressed: count == null ? _start : null,
                      ),
                      const SizedBox(height: 12),
                      if (count != null)
                        TextButton(
                          onPressed: _cancel,
                          child: const Text('یه لحظه، هنوز آماده نیستم'),
                        )
                      else
                        const Text(
                          'با شمارش معکوس ۳ ثانیه‌ای شروع می‌کنیم',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                    ],
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
