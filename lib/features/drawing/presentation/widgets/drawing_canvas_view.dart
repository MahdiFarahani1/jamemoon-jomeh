import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../cubit/drawing_state.dart';

// Smooth finger drawing canvas with CustomPainter (Zero setState)
class DrawingCanvasView extends StatelessWidget {
  final List<DrawnStroke> completedStrokes;
  final Color activeColor;
  final double strokeWidth;
  final bool isEraser;
  final void Function(DrawnStroke stroke) onStrokeFinished;

  const DrawingCanvasView({
    super.key,
    required this.completedStrokes,
    required this.activeColor,
    required this.strokeWidth,
    required this.isEraser,
    required this.onStrokeFinished,
  });

  @override
  Widget build(BuildContext context) {
    final activePointsNotifier = ValueNotifier<List<Offset>>([]);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onPanStart: (details) {
          activePointsNotifier.value = [details.localPosition];
        },
        onPanUpdate: (details) {
          final updated = List<Offset>.from(activePointsNotifier.value)
            ..add(details.localPosition);
          activePointsNotifier.value = updated;
        },
        onPanEnd: (_) {
          if (activePointsNotifier.value.isNotEmpty) {
            onStrokeFinished(
              DrawnStroke(
                points: List<Offset>.from(activePointsNotifier.value),
                color: isEraser ? AppColors.surface : activeColor,
                strokeWidth: isEraser ? strokeWidth * 3 : strokeWidth,
                isEraser: isEraser,
              ),
            );
            activePointsNotifier.value = [];
          }
        },
        child: ValueListenableBuilder<List<Offset>>(
          valueListenable: activePointsNotifier,
          builder: (context, activePoints, _) {
            return RepaintBoundary(
              child: CustomPaint(
                painter: _DrawingPainter(
                  strokes: completedStrokes,
                  activePoints: activePoints,
                  activeColor: isEraser ? AppColors.surface : activeColor,
                  activeStrokeWidth: isEraser ? strokeWidth * 3 : strokeWidth,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  final List<Offset> activePoints;
  final Color activeColor;
  final double activeStrokeWidth;

  _DrawingPainter({
    required this.strokes,
    required this.activePoints,
    required this.activeColor,
    required this.activeStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // 2. Draw currently active stroke
    if (activePoints.length >= 2) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = activeStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final activePath = Path()..moveTo(activePoints.first.dx, activePoints.first.dy);
      for (int i = 1; i < activePoints.length; i++) {
        activePath.lineTo(activePoints[i].dx, activePoints[i].dy);
      }
      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

