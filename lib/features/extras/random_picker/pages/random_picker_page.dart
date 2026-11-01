import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_card.dart';
import '../../../teams/presentation/cubit/teams_cubit.dart';
import '../../../teams/presentation/cubit/teams_state.dart';

// Random Player Lottery Picker (Zero setState)
class RandomPickerPage extends StatelessWidget {
  const RandomPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chosenPlayerNotifier = ValueNotifier<String?>(null);
    final isShufflingNotifier = ValueNotifier<bool>(false);
    final random = Random();

    return Scaffold(
      appBar: AppBar(
        title: const Text('قرعه‌کشی و انتخاب تصادفی'),
      ),
      body: AnimatedPartyBackground(
        child: BlocBuilder<TeamsCubit, TeamsState>(
          builder: (context, state) {
            final playersList = state.players.isNotEmpty
                ? state.players.map((p) => p.name).toList()
                : ['سارا', 'امیرعلی', 'نیلوفر', 'مهدی', 'ریحانه', 'محمدرضا'];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'نمی‌دونید نوبت کیه یا کی باید اول بازی کنه؟ قرعه‌کشی کنید!',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),

                  // Selected Player Display
                  ValueListenableBuilder<String?>(
                    valueListenable: chosenPlayerNotifier,
                    builder: (context, chosen, _) {
                      return PartyCard(
                        gradient: AppColors.purpleGradient,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 68),
                            const SizedBox(height: 14),
                            Text(
                              chosen ?? 'آماده قرعه‌کشی...',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(),

                  // Draw button
                  ValueListenableBuilder<bool>(
                    valueListenable: isShufflingNotifier,
                    builder: (context, isShuffling, _) {
                      return PartyButton(
                        label: isShuffling ? 'در حال انتخاب...' : 'قرعه بنداز!',
                        icon: Icons.shuffle_rounded,
                        color: AppColors.primary,
                        onPressed: isShuffling
                            ? null
                            : () async {
                                isShufflingNotifier.value = true;
                                sl<AudioService>().playTick();
                                sl<HapticsService>().mediumBump();

                                // Quick cycling visual effect
                                for (int i = 0; i < 10; i++) {
                                  chosenPlayerNotifier.value = playersList[random.nextInt(playersList.length)];
                                  await Future.delayed(const Duration(milliseconds: 100));
                                }

                                final finalPick = playersList[random.nextInt(playersList.length)];
                                chosenPlayerNotifier.value = finalPick;
                                sl<AudioService>().playVictory();
                                sl<HapticsService>().lightClick();
                                isShufflingNotifier.value = false;
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
