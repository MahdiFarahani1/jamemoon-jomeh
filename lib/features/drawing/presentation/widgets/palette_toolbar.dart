import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaletteToolbar extends StatelessWidget {
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
  final Color activeColor;
  final double strokeWidth;
  final bool isEraser;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onToggleEraser, onUndo, onClear;
  static const palette = [
    Colors.white,
    Color(0xFFFF5252),
    Color(0xFFFFEB3B),
    Color(0xFF40C4FF),
    Color(0xFF69F0AE),
    Color(0xFFE040FB),
  ];
  static const _names = ['سفید', 'قرمز', 'زرد', 'آبی', 'سبز', 'بنفش'];
  @override
  Widget build(BuildContext context) {
    final colors = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < palette.length; i++)
            Semantics(
              button: true,
              selected:
                  !isEraser && palette[i].toARGB32() == activeColor.toARGB32(),
              label: 'رنگ ${_names[i]}',
              child: Tooltip(
                message: _names[i],
                child: InkWell(
                  onTap: () => onColorChanged(palette[i]),
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 150),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: palette[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                !isEraser &&
                                    palette[i].toARGB32() ==
                                        activeColor.toARGB32()
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child:
                            !isEraser &&
                                palette[i].toARGB32() == activeColor.toARGB32()
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.background,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final tools = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: 'پاک‌کن',
          isSelected: isEraser,
          selectedIcon: const Icon(
            Icons.auto_fix_high_rounded,
            color: AppColors.accent,
          ),
          icon: const Icon(Icons.auto_fix_high_outlined),
          onPressed: onToggleEraser,
        ),
        IconButton(
          tooltip: 'اندازه قلم',
          icon: Icon(
            Icons.circle,
            size: strokeWidth > 7
                ? 22
                : strokeWidth > 4
                ? 16
                : 10,
          ),
          onPressed: () => onStrokeWidthChanged(
            strokeWidth <= 4
                ? 7
                : strokeWidth <= 7
                ? 12
                : 3,
          ),
        ),
        IconButton(
          tooltip: 'بازگشت آخرین خط',
          icon: const Icon(Icons.undo_rounded),
          onPressed: onUndo,
        ),
        IconButton(
          tooltip: 'پاک کردن کل بوم',
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
          ),
          onPressed: onClear,
        ),
      ],
    );
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 560
              ? Row(
                  children: [
                    Expanded(child: colors),
                    SizedBox(width: 208, child: tools),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    colors,
                    const Divider(height: 8, indent: 8, endIndent: 8),
                    tools,
                  ],
                ),
        ),
      ),
    );
  }
}
