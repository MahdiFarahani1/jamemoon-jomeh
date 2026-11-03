import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/core/widgets/brand_mark.dart';

// Run with: flutter test tool/render_brand_assets.dart
// Renders the native vector mark into legacy Android launcher sizes.
void main() {
  test('render launcher artwork', () async {
    final logoRecorder = ui.PictureRecorder();
    const BrandMarkPainter().paint(
      Canvas(logoRecorder),
      const Size.square(1024),
    );
    final logoPicture = logoRecorder.endRecording();
    final logoImage = await logoPicture.toImage(1024, 1024);
    final logoData = await logoImage.toByteData(format: ui.ImageByteFormat.png);
    await Directory('assets/brand').create(recursive: true);
    await File('assets/brand/jamemoon-mark.png')
        .writeAsBytes(logoData!.buffer.asUint8List());
    logoImage.dispose();
    logoPicture.dispose();
    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = entry.value.toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size, size),
          Radius.circular(size * .22),
        ),
        Paint()..color = AppColors.background,
      );
      canvas.translate(size * .08, size * .08);
      const BrandMarkPainter().paint(canvas, Size.square(size * .84));
      final picture = recorder.endRecording();
      final image = await picture.toImage(entry.value, entry.value);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      );
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  });
}
