import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'party_button.dart';

// Styled party alert and confirmation dialog
class PartyDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
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
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PartyDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
            Row(
              children: [
                Expanded(
                  child: PartyButton(
                    label: cancelLabel,
                    color: AppColors.surfaceLight,
                    textColor: AppColors.textParagraph,
                    shadowColor: AppColors.surfaceBorder,
                    onPressed: () {
                      onCancel?.call();
                      Navigator.of(context).pop(false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PartyButton(
                    label: confirmLabel,
                    color: confirmColor,
                    onPressed: () {
                      onConfirm();
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
