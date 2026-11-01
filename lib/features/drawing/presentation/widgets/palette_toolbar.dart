import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

// Palette and tools bar for drawing (Zero setState)
class PaletteToolbar extends StatelessWidget {
  final Color activeColor;
  final double strokeWidth;
  final bool isEraser;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onToggleEraser;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  const PaletteToolbar({
    super.key,
    required this.activeColor,
    required this.strokeWidth,
    required this.isEraser,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onToggleEraser,
    required this.onUndo,
    required this.onClear,
  });

  static const List<Color> palette = [
    Colors.white,
    Color(0xFFFF5252),
    Color(0xFFFFEB3B),
    Color(0xFF40C4FF),
    Color(0xFF69F0AE),
    Color(0xFFE040FB),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          // Color choices
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: palette.map((c) {
                final isSelected = !isEraser && c.value == activeColor.value;
                return GestureDetector(
                  onTap: () => onColorChanged(c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const VerticalDivider(color: AppColors.surfaceBorder, width: 20),

          // Eraser
          IconButton(
            tooltip: 'پاک‌کن',
            icon: Icon(
              Icons.auto_fix_high_rounded,
              color: isEraser ? AppColors.accent : AppColors.textParagraph,
              size: 22,
            ),
            onPressed: onToggleEraser,
          ),

          // Stroke width toggle (cycles 3, 6, 10)
          IconButton(
            tooltip: 'اندازه قلم',
            icon: Icon(
              strokeWidth > 7
                  ? Icons.lens_rounded
                  : (strokeWidth > 4 ? Icons.radio_button_checked_rounded : Icons.fiber_manual_record_rounded),
              color: AppColors.textParagraph,
              size: 22,
            ),
            onPressed: () {
              if (strokeWidth <= 4) {
                onStrokeWidthChanged(7.0);
              } else if (strokeWidth <= 7) {
                onStrokeWidthChanged(12.0);
              } else {
                onStrokeWidthChanged(3.0);
              }
            },
          ),

          // Undo
          IconButton(
            tooltip: 'بازگشت آخرین خط',
            icon: const Icon(Icons.undo_rounded, color: AppColors.textParagraph, size: 22),
            onPressed: onUndo,
          ),

          // Clear
          IconButton(
            tooltip: 'پاک کردن کل بوم',
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 22),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

