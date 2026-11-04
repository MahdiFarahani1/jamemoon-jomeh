import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../teams/presentation/cubit/teams_cubit.dart';
import '../../../teams/presentation/cubit/teams_state.dart';
import '../../cubit/extras_cubit.dart';

class RandomPickerPage extends StatelessWidget {
  const RandomPickerPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PickerCubit(),
    child: Scaffold(
      appBar: AppBar(title: const Text('قرعه‌کشی')),
      body: AnimatedPartyBackground(
        child: SafeArea(
          top: false,
          child: BlocBuilder<TeamsCubit, TeamsState>(
            builder: (context, teams) {
              final players = teams.players.map((p) => p.name).toList();
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'نوبت کیه شام رو حساب کنه؟',
                    style: AppTypography.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'از بین بازیکن‌های جمع، یک نفر انتخاب می‌شود.',
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 48,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.accent,
                          size: 64,
                        ),
                        const SizedBox(height: 18),
                        BlocBuilder<PickerCubit, PickerState>(
                          builder: (context, state) => Text(
                            players.isEmpty
                                ? 'هنوز بازیکنی ندارید'
                                : state.name ?? 'آماده‌ای؟',
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (players.isEmpty)
                    PartyButton(
                      label: 'افزودن بازیکن',
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/teams'),
                    )
                  else
                    BlocBuilder<PickerCubit, PickerState>(
                      builder: (context, state) => PartyButton(
                        label: state.busy ? 'در حال انتخاب...' : 'قرعه بنداز!',
                        icon: Icons.shuffle_rounded,
                        onPressed: state.busy
                            ? null
                            : () => context.read<PickerCubit>().pick(players),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
