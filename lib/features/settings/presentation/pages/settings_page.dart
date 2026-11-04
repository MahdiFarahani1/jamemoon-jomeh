import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_dialog.dart';
import '../../../../core/widgets/party_switch.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../teams/presentation/cubit/teams_cubit.dart';
import '../../../tournament/presentation/cubit/tournament_cubit.dart';
import '../../../shop/presentation/cubit/shop_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static final _bazaarUrl = Uri.parse(
    'https://cafebazaar.ir/app/com.denver.jam',
  );

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _rateApp(BuildContext context) async {
    try {
      if (await launchUrl(_bazaarUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      _showError(context, 'صفحهٔ برنامه در کافه‌بازار باز نشد.');
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: 'بیا با «جمعمون جمعه!» بازی کنیم!\n$_bazaarUrl',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'اشتراک‌گذاری برنامه انجام نشد.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تنظیمات')),
    body: AnimatedPartyBackground(
      child: SafeArea(
        top: false,
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Text(
                'دورهمی به سلیقه شما',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'صدا و بازخورد بازی را همین‌جا تنظیم کنید.',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 24),
              _SettingRow(
                icon: Icons.volume_up_rounded,
                title: 'صداهای بازی',
                description: 'صداهای تایمر و جشن',
                value: state.soundEnabled,
                onChanged: (_) => context.read<SettingsCubit>().toggleSound(),
              ),
              const SizedBox(height: 10),
              _SettingRow(
                icon: Icons.vibration_rounded,
                title: 'بازخورد لمسی',
                description: 'لرزش هنگام بازی و لمس دکمه‌ها',
                value: state.vibrationEnabled,
                onChanged: (_) =>
                    context.read<SettingsCubit>().toggleVibration(),
              ),
              const SizedBox(height: 10),
              _SettingRow(
                icon: Icons.music_note_rounded,
                title: 'موسیقی بازی',
                description: 'موسیقی زمینه برنامه‌ریزی و عملیات',
                value: state.musicEnabled,
                onChanged: (_) => context.read<SettingsCubit>().toggleMusic(),
              ),
              const SizedBox(height: 32),
              const Text(
                'دوستان و بازخورد',
                style: AppTypography.headlineLarge,
              ),
              const SizedBox(height: 12),
              _ActionRow(
                icon: Icons.star_rate_rounded,
                title: 'نظر دادن به برنامه',
                description: 'صفحهٔ برنامه در کافه‌بازار',
                onTap: () => _rateApp(context),
              ),
              const SizedBox(height: 10),
              _ActionRow(
                icon: Icons.share_rounded,
                title: 'ارسال اپ برای دوستان',
                description: 'فرستادن لینک برنامه',
                onTap: () => _shareApp(context),
              ),
              const SizedBox(height: 32),
              const Text('داده‌های بازی', style: AppTypography.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                'بازنشانی، تیم‌ها، کارت‌ها و تاریخچه را پاک می‌کند. دسترسی‌های خریداری‌شده حفظ می‌شوند.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              PartyButton(
                label: 'بازنشانی اطلاعات بازی',
                icon: Icons.restart_alt_rounded,
                color: AppColors.surfaceLight,
                textColor: AppColors.textHeadline,
                onPressed: () async {
                  final confirmed = await PartyDialog.show(
                    context,
                    title: 'بازنشانی بازی',
                    message: 'تیم‌ها، بازیکن‌ها، کارت‌ها و تاریخچه پاک می‌شوند. ادامه می‌دهید؟',
                    confirmLabel: 'بازنشانی',
                  );
                  if (confirmed != true || !context.mounted) return;
                  final settings = context.read<SettingsCubit>();
                  final teams = context.read<TeamsCubit>();
                  final tournament = context.read<TournamentCubit>();
                  final shop = context.read<ShopCubit>();
                  await settings.resetAll();
                  teams.loadSavedTeams();
                  tournament.reloadFromStorage();
                  shop.loadProducts();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('اطلاعات بازی بازنشانی شد.'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 36),
              Center(
                child: Column(
                  children: [
                    const BrandMark(size: 54),
                    const SizedBox(height: 8),
                    const Text(
                      'جمعمون جمعه!',
                      style: AppTypography.headlineMedium,
                    ),
                    Text(
                      'برای خنده‌های کنار هم',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.headlineMedium),
                  Text(description, style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.accent),
          ],
        ),
      ),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, description;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.headlineMedium),
              Text(description, style: AppTypography.bodyMedium),
            ],
          ),
        ),
        PartySwitch(value: value, onChanged: onChanged),
      ],
    ),
  );
}
