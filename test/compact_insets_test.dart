import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/app/theme/app_theme.dart';
import 'package:flutter_application_1/core/services/purchase_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/features/extras/custom_cards/pages/custom_cards_page.dart';
import 'package:flutter_application_1/features/extras/lucky_wheel/pages/lucky_wheel_page.dart';
import 'package:flutter_application_1/features/extras/random_picker/pages/random_picker_page.dart';
import 'package:flutter_application_1/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter_application_1/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_application_1/features/shop/presentation/cubit/shop_cubit.dart';
import 'package:flutter_application_1/features/shop/presentation/pages/shop_page.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/teams/presentation/pages/teams_setup_page.dart';
import 'package:flutter_application_1/features/tournament/presentation/cubit/tournament_cubit.dart';
import 'package:flutter_application_1/features/tournament/presentation/pages/tournament_lobby_page.dart';

void main() {
  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    sl.registerSingleton<StorageService>(
      StorageService(await SharedPreferences.getInstance()),
    );
  });

  tearDown(() async => sl.reset());

  testWidgets(
    'utility pages keep content and primary actions inside compact system insets',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = sl<StorageService>();
      final teams = TeamsCubit(storage);
      final tournament = TournamentCubit(
        storageService: storage,
        teamsCubit: teams,
      );
      final settings = SettingsCubit(storage);
      final shop = ShopCubit(LocalPurchaseService(storage));

      final cases = <({String name, Widget page, Finder Function() action})>[
        (
          name: 'settings',
          page: const SettingsPage(),
          action: () => find.text('بازنشانی اطلاعات بازی'),
        ),
        (
          name: 'shop',
          page: const ShopPage(),
          action: () => find.text('مشاهده جزئیات'),
        ),
        (
          name: 'teams',
          page: const TeamsSetupPage(),
          action: () => find.text('افزودن بازیکن'),
        ),
        (
          name: 'tournament',
          page: const TournamentLobbyPage(),
          action: () => find.textContaining('شروع رقابت در'),
        ),
        (
          name: 'custom cards',
          page: const CustomCardsPage(),
          action: () => find.text('ساخت اولین کارت'),
        ),
        (
          name: 'lucky wheel',
          page: const LuckyWheelPage(),
          action: () => find.text('بچرخون!'),
        ),
        (
          name: 'random picker',
          page: const RandomPickerPage(),
          action: () => find.text('افزودن بازیکن'),
        ),
      ];

      for (final testCase in cases) {
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: teams),
              BlocProvider.value(value: tournament),
              BlocProvider.value(value: settings),
              BlocProvider.value(value: shop),
            ],
            child: _CompactApp(home: testCase.page),
          ),
        );
        await tester.pumpAndSettle();

        final background = find.byType(AnimatedPartyBackground);
        expect(background, findsOneWidget, reason: testCase.name);
        expect(
          find.descendant(of: background, matching: find.byType(SafeArea)),
          findsOneWidget,
          reason: testCase.name,
        );
        expect(tester.takeException(), isNull, reason: testCase.name);

        final action = testCase.action();
        final scrollable = find
            .descendant(of: background, matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(
          action,
          160,
          scrollable: scrollable,
          maxScrolls: 24,
        );
        await tester.pumpAndSettle();
        expect(action, findsWidgets, reason: testCase.name);
        expect(tester.takeException(), isNull, reason: testCase.name);

        final actionRect = tester.getRect(action.first);
        expect(actionRect.top, greaterThanOrEqualTo(0), reason: testCase.name);
        expect(
          actionRect.bottom,
          lessThanOrEqualTo(534),
          reason: testCase.name,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }

      await settings.close();
      await shop.close();
      await tournament.close();
      await teams.close();
    },
  );
}

class _CompactApp extends StatelessWidget {
  const _CompactApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('fa', 'IR'),
    supportedLocales: const [Locale('fa', 'IR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routes: {
      '/teams': (_) => const Scaffold(body: Text('Team setup')),
      '/game/charades': (_) => const Scaffold(body: Text('Game')),
    },
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.6),
        padding: const EdgeInsets.only(bottom: 34),
        viewPadding: const EdgeInsets.only(bottom: 34),
        disableAnimations: true,
      ),
      child: Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
    home: home,
  );
}
