import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/app/theme/app_theme.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/core/widgets/pass_phone_overlay.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/taboo/presentation/pages/taboo_game_page.dart';
import 'package:flutter_application_1/features/taboo/presentation/cubit/taboo_cubit.dart';
import 'package:flutter_application_1/features/charades/presentation/pages/charades_game_page.dart';
import 'package:flutter_application_1/features/drawing/presentation/pages/drawing_game_page.dart';
import 'package:flutter_application_1/features/five_seconds/presentation/pages/five_seconds_game_page.dart';
import 'package:flutter_application_1/features/hot_potato/presentation/pages/hot_potato_game_page.dart';
import 'package:flutter_application_1/features/decoder/presentation/pages/decoder_game_page.dart';
import 'package:flutter_application_1/features/decoder/presentation/cubit/decoder_cubit.dart';
import 'package:flutter_application_1/features/extras/party_challenges/party_challenges_page.dart';
import 'package:flutter_application_1/core/widgets/game_scene.dart';

// Exports reviewable screenshots from the actual Flutter widgets, using local fonts.
void main() {
  testWidgets('export redesign previews', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({
      'sound_enabled': false,
      'vibration_enabled': false,
    });
    await sl.reset();
    await initDependencies();
    await tester.runAsync(() async {
      final loader = FontLoader('Vazirmatn')
        ..addFont(rootBundle.load('assets/fonts/Vazirmatn.ttf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final key = GlobalKey();
    Widget app(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, navigator) =>
          RepaintBoundary(key: key, child: navigator!),
      home: BlocProvider(
        create: (_) => TeamsCubit(sl<StorageService>()),
        child: child,
      ),
    );
    Future<void> save(String name, {bool settle = true}) async {
      if (settle) await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/design').create(recursive: true);
        await File('build/design/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(app(const HomePage()));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/art/party-trophy.png'),
        key.currentContext!,
      );
    });
    await save('home');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -530));
    await save('games');
    await tester.ensureVisible(find.text('تابو'));
    await tester.tap(find.text('تابو'));
    await save('game-mode');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      app(
        Scaffold(
          body: PassPhoneOverlay(
            teamName: 'تیم پلنگ‌ها',
            gameTitle: 'پانتومیم انفجاری',
            onReady: () {},
          ),
        ),
      ),
    );
    await save('handoff');
    for (final entry in <String, Widget>{
      'taboo': const TabooGamePage(isQuickMode: true),
      'charades': const CharadesGamePage(isQuickMode: true),
      'drawing': const DrawingGamePage(isQuickMode: true),
      'five_seconds': const FiveSecondsGamePage(isQuickMode: true),
      'hot_potato': const HotPotatoGamePage(isQuickMode: true),
    }.entries) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(entry.value));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('آماده‌ام، شروع کن!'));
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      if (entry.key == 'drawing') {
        await tester.tap(find.text('آماده‌ام، بریم روی بوم!'));
        await tester.pumpAndSettle();
      }
      await save('arena-${entry.key}');
      if (entry.key == 'taboo') {
        tester
            .element(find.byType(GameSceneRibbon))
            .read<TabooCubit>()
            .onCorrect();
        await tester.pump();
        for (var frame = 0; frame < 6; frame++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
        await save('arena-taboo-reward', settle: false);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(const DecoderGamePage()));
    await tester.pumpAndSettle();
    final decoderContext = tester.element(find.byType(GameSceneRibbon));
    final teams = decoderContext.read<TeamsCubit>().state.teams;
    await tester.runAsync(
      () => decoderContext.read<DecoderCubit>().startGame(teams[0], teams[1]),
    );
    await tester.pumpAndSettle();
    decoderContext.read<DecoderCubit>().dismissShield();
    await tester.pumpAndSettle();
    decoderContext.read<DecoderCubit>().showMap();
    await save('arena-decoder');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(const PartyChallengesPage()));
    await save('challenges');
    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });
}
