import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../cubit/drawing_state.dart';

class DrawingCanvasView extends StatefulWidget {
  const DrawingCanvasView({
    super.key,
    required this.completedStrokes,
    required this.activeColor,
    required this.strokeWidth,
    required this.isEraser,
    required this.onStrokeFinished,
  });

  final List<DrawnStroke> completedStrokes;
  final Color activeColor;
  final double strokeWidth;
  final bool isEraser;
  final void Function(DrawnStroke stroke) onStrokeFinished;

  @override
  State<DrawingCanvasView> createState() => _DrawingCanvasViewState();
}

class _ActiveStroke extends ChangeNotifier {
  final List<Offset> points = [];
  Path path = Path();
  Color color = Colors.white;
  double width = 4;
  bool eraser = false;

  void begin(Offset point, Color color, double width, bool eraser) {
    points.clear();
    points.add(point);
    path = Path()..moveTo(point.dx, point.dy);
    this.color = color;
    this.width = width;
    this.eraser = eraser;
    notifyListeners();
  }

  void add(Offset point) {
    points.add(point);
    path.lineTo(point.dx, point.dy);
    notifyListeners();
  }

  void clear() {
    points.clear();
    path = Path();
    notifyListeners();
  }
}

class _DrawingCanvasViewState extends State<DrawingCanvasView> {
  final _active = _ActiveStroke();

  void _begin(Offset point) => _active.begin(
    point,
    widget.isEraser ? AppColors.surface : widget.activeColor,
    widget.isEraser ? widget.strokeWidth * 3 : widget.strokeWidth,
    widget.isEraser,
  );

  void _finish() {
    if (_active.points.isEmpty) return;
    final stroke = DrawnStroke(
      points: List.of(_active.points),
      color: _active.color,
      strokeWidth: _active.width,
      isEraser: _active.eraser,
    );
    _active.clear();
    widget.onStrokeFinished(stroke);
  }

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.drawPrimary.withValues(alpha: .4),
        width: 2,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (event) => _begin(event.localPosition),
      onPanUpdate: (event) => _active.add(event.localPosition),
      onPanEnd: (_) => _finish(),
      onPanCancel: _finish,
      onTapUp: (event) {
        _begin(event.localPosition);
        _finish();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.completedStrokes.isEmpty)
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gesture_rounded,
                        size: 42,
                        color: AppColors.drawPrimary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'اینجا شاهکارت رو بکش!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          RepaintBoundary(
            child: CustomPaint(
              painter: _CompletedPainter(widget.completedStrokes),
            ),
          ),
          RepaintBoundary(child: CustomPaint(painter: _ActivePainter(_active))),
        ],
      ),
    ),
  );
}

Paint _paint(Color color, double width) => Paint()
  ..color = color
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;

void _draw(Canvas canvas, List<Offset> points, Path path, Paint paint) {
  if (points.isEmpty) return;
  if (points.length == 1) {
    canvas.drawCircle(
      points.first,
      paint.strokeWidth / 2,
      Paint()..color = paint.color,
    );
  } else {
    canvas.drawPath(path, paint);
  }
}

class _CompletedPainter extends CustomPainter {
  _CompletedPainter(this.strokes);
  final List<DrawnStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      _draw(
        canvas,
        stroke.points,
        path,
        _paint(stroke.color, stroke.strokeWidth),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompletedPainter old) => old.strokes != strokes;
}

class _ActivePainter extends CustomPainter {
  _ActivePainter(this.stroke) : super(repaint: stroke);
  final _ActiveStroke stroke;

  @override
  void paint(Canvas canvas, Size size) => _draw(
    canvas,
    stroke.points,
    stroke.path,
    _paint(stroke.color, stroke.width),
  );

  @override
  bool shouldRepaint(covariant _ActivePainter old) => old.stroke != stroke;
}
