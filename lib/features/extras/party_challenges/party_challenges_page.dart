import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/round_clock.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../../../../core/widgets/custom_timer_widget.dart';
import '../../../../core/widgets/party_button.dart';
import 'challenge_deck.dart';

/// An optional, unscored intermission. Nothing starts until the group is ready.
class PartyChallengesPage extends StatefulWidget {
  const PartyChallengesPage({super.key});
  @override
  State<PartyChallengesPage> createState() => _PartyChallengesPageState();
}

class _PartyChallengesPageState extends State<PartyChallengesPage>
    with WidgetsBindingObserver {
  final _deck = ChallengeDeck();
  final ValueNotifier<int> _revision = ValueNotifier(0);
  void _refresh() => _revision.value++;
  late PartyChallenge _card;
  late final RoundClock _clock;
  ChallengeKind? _kind;
  Animation<double>? _secondaryAnimation;
  int _remaining = 30, _completed = 0, _serial = 0;
  bool _running = false, _done = false, _started = false;
  int get _poolSize =>
      challenges.where((c) => _kind == null || c.kind == _kind).length;

  @override
  void initState() {
    super.initState();
    _card = _deck.draw();
    _remaining = _card.seconds;
    _clock = RoundClock(
      onChanged: (left) {
        final seconds = (left.inMilliseconds / 1000).ceil();
        if (mounted && seconds != _remaining) {
          _remaining = seconds;
          _refresh();
        }
      },
      onFinished: () {
        if (!mounted) return;
        _running = false;
        _refresh();
        _sound(GameSound.timeUp);
      },
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void _sound(GameSound sound) {
    if (sl.isRegistered<AudioService>()) {
      unawaited(sl<AudioService>().play(sound));
    }
  }

  void _pause() {
    _clock.pause();
    if (_running && mounted) {
      _remaining = (_clock.remaining.inMilliseconds / 1000).ceil();
      _running = false;
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.secondaryAnimation;
    if (_secondaryAnimation != animation) {
      _secondaryAnimation?.removeListener(_onRouteChanged);
      _secondaryAnimation = animation;
      animation?.addListener(_onRouteChanged);
    }
  }

  void _onRouteChanged() {
    if (ModalRoute.of(context)?.isCurrent == false) _pause();
  }

  void _next([ChallengeKind? kind]) {
    _clock.pause();
    _kind = kind;
    _card = _deck.draw(kind);
    _remaining = _card.seconds;
    _running = false;
    _done = false;
    _started = false;
    _serial++;
    _refresh();
    _sound(GameSound.reveal);
  }

  void _toggleClock() {
    if (_running) {
      _pause();
      return;
    }
    if (_done || _remaining == 0) return;
    _running = true;
    if (!_started) {
      _started = true;
      _clock.start(Duration(seconds: _card.seconds));
    } else {
      _clock.resume();
    }
    _refresh();
  }

  void _complete() {
    if (_done) return;
    _clock.pause();
    _running = false;
    _done = true;
    _completed++;
    _refresh();
    _sound(GameSound.correct);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _secondaryAnimation?.removeListener(_onRouteChanged);
    _clock.dispose();
    _revision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: _revision,
    builder: (context, _, _) => Scaffold(
      appBar: AppBar(
        title: const Text('چالش جمع'),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 16),
            child: BrandMark(size: 40),
          ),
        ],
      ),
      body: AnimatedPartyBackground(
        gameKey: 'charades',
        child: SafeArea(
          child: ConfettiOverlay(
            key: ValueKey('confetti-$_serial-$_done'),
            showConfetti: _done,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const Text(
                  'یه کارت، یه خاطره!',
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'بدون امتیاز و رقابت؛ فقط برای خندهٔ جمع. هر کارتی رو هم دوست نداشتید، عوض کنید.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: const Text('همه'),
                      selected: _kind == null,
                      labelStyle: TextStyle(
                        color: _kind == null
                            ? AppColors.background
                            : AppColors.textParagraph,
                      ),
                      onSelected: (_) {
                        if (_kind != null) _next();
                      },
                    ),
                    for (final kind in ChallengeKind.values)
                      ChoiceChip(
                        label: Text(kind.label),
                        selected: _kind == kind,
                        labelStyle: TextStyle(
                          color: _kind == kind
                              ? AppColors.background
                              : AppColors.textParagraph,
                        ),
                        onSelected: (_) {
                          if (_kind != kind) _next(kind);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                PartyEntrance(
                  key: ValueKey(_serial),
                  offset: 10,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF383254), Color(0xFF24263E)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.charadesPrimary.withValues(alpha: .4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const BrandMark(size: 90),
                        const SizedBox(height: 12),
                        Text(
                          _card.kind.label,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _card.title,
                          style: AppTypography.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _card.instruction,
                          style: AppTypography.bodyLarge.copyWith(height: 1.9),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _done
                                ? 'عالی بود! یکی دیگه؟'
                                : _remaining == 0
                                ? 'وقت تموم شد؛ اگه دوست دارید ادامه بدید!'
                                : 'زمان‌سنج اختیاری؛ عجله‌ای نیست',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: _done
                                  ? AppColors.success
                                  : AppColors.textParagraph,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CustomTimerWidget(
                      remainingSeconds: _remaining,
                      totalSeconds: _card.seconds,
                      size: 64,
                      activeColor: AppColors.charadesPrimary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _done || _remaining == 0
                            ? null
                            : _toggleClock,
                        icon: Icon(
                          _running ? Icons.pause_rounded : Icons.timer_outlined,
                        ),
                        label: Text(
                          _running
                              ? 'توقف زمان'
                              : !_started
                              ? 'شروع ۳۰ ثانیه'
                              : 'ادامهٔ زمان',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!_done) ...[
                  PartyButton(
                    label: 'انجامش دادیم!',
                    icon: Icons.celebration_rounded,
                    color: AppColors.success,
                    onPressed: _complete,
                  ),
                  const SizedBox(height: 12),
                ],
                PartyButton(
                  label: _done ? 'چالش بعدی' : 'یه کارت دیگه',
                  icon: Icons.shuffle_rounded,
                  color: _done
                      ? AppColors.charadesPrimary
                      : AppColors.surfaceLight,
                  textColor: _done
                      ? AppColors.background
                      : AppColors.textHeadline,
                  onPressed: () => _next(_kind),
                ),
                const SizedBox(height: 18),
                Text(
                  '$_completed چالش انجام دادید  •  $_poolSize کارت در این بخش',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                if (_deck.reshuffled)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'کارت‌های این بخش تموم شد و دوباره بُر خورد!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
