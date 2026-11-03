import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'party_button.dart';

class PartyDialog extends StatelessWidget {
  final String title, message, confirmLabel, cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color confirmColor;
  const PartyDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'تایید و ادامه',
    this.cancelLabel = 'انصراف',
    required this.onConfirm,
    this.onCancel,
    this.confirmColor = AppColors.error,
  });
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'تایید',
    String cancelLabel = 'انصراف',
    Color confirmColor = AppColors.error,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => PartyDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmColor: confirmColor,
      onConfirm: () {},
      onCancel: () {},
    ),
  );
  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PartyButton(
            label: confirmLabel,
            color: confirmColor,
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: 12),
          PartyButton(
            label: cancelLabel,
            color: AppColors.surfaceLight,
            onPressed: () {
              onCancel?.call();
              Navigator.of(context).pop(false);
            },
          ),
        ],
      ),
    ),
  );
}
