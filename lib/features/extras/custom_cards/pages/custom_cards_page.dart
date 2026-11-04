import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../cubit/extras_cubit.dart';

class CustomCardsPage extends StatelessWidget {
  const CustomCardsPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CustomCardsCubit(sl<StorageService>()),
    child: const _CardsView(),
  );
}

class _CardsView extends StatelessWidget {
  const _CardsView();
  void _add(BuildContext context) {
    final cubit = context.read<CustomCardsCubit>();
    showDialog<void>(
      context: context,
      builder: (_) => _CardDialog(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('کارت‌های من'),
      actions: [
        IconButton(
          tooltip: 'افزودن کارت',
          onPressed: () => _add(context),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    ),
    body: AnimatedPartyBackground(
      child: SafeArea(
        top: false,
        child: BlocBuilder<CustomCardsCubit, List<Map<String, dynamic>>>(
          builder: (context, cards) => ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Text(
                'شوخی‌های مخصوص جمع شما',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'کلمه‌ها و خاطره‌های خودتان را به بازی بیاورید.',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'کارت‌های شما در دستهٔ «کارت‌های من» پانتومیم هم نمایش داده می‌شوند.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 22),
              if (cards.isEmpty) ...[
                const SizedBox(height: 40),
                const Icon(
                  Icons.style_outlined,
                  size: 80,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 18),
                const Text(
                  'هنوز کارتی نساخته‌اید',
                  style: AppTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'اولین کارت را برای دورهمی بعدی بسازید.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PartyButton(
                  label: 'ساخت اولین کارت',
                  icon: Icons.add_rounded,
                  onPressed: () => _add(context),
                ),
              ] else ...[
                PartyButton(
                  label: 'کارت تازه',
                  icon: Icons.add_rounded,
                  onPressed: () => _add(context),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < cards.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      12,
                      8,
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.style_outlined,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cards[i]['word'] ?? ''}',
                                style: AppTypography.headlineMedium,
                              ),
                              Text(
                                '${cards[i]['category'] ?? 'شخصی'}',
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف کارت',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () =>
                              context.read<CustomCardsCubit>().remove(i),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _CardDialog extends StatefulWidget {
  const _CardDialog({required this.cubit});
  final CustomCardsCubit cubit;
  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  final word = TextEditingController();
  final category = TextEditingController();
  @override
  void dispose() {
    word.dispose();
    category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('کارت تازه', style: AppTypography.headlineLarge),
          const SizedBox(height: 16),
          TextField(
            controller: word,
            decoration: const InputDecoration(labelText: 'کلمه یا عبارت'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: category,
            decoration: const InputDecoration(labelText: 'دسته‌بندی (اختیاری)'),
          ),
          const SizedBox(height: 22),
          PartyButton(
            label: 'ثبت کارت',
            onPressed: () async {
              if (word.text.trim().isEmpty) return;
              await widget.cubit.add(word.text, category.text);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
