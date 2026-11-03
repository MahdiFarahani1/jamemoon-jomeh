import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/theme/app_theme.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/teams/presentation/pages/game_preparation_page.dart';

void main() {
  testWidgets('capture every preparation screen', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final key = GlobalKey();
    Directory('build/design').createSync(recursive: true);
    for (final game in [
      'taboo',
      'hot_potato',
      'charades',
      'five_seconds',
      'drawing',
    ]) {
      SharedPreferences.setMockInitialValues({});
      final cubit = TeamsCubit(
        StorageService(await SharedPreferences.getInstance()),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => RepaintBoundary(
          key: key,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
        home: BlocProvider.value(
          value: cubit,
          child: GamePreparationPage(gameKey: game),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/design/setup-$game.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await cubit.close();
    }
  });
}
