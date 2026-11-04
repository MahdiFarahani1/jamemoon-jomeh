import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/app/router.dart';
import 'package:flutter_application_1/app/theme/app_theme.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/purchase_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/features/home/presentation/home_page.dart';
import 'package:flutter_application_1/features/shop/presentation/cubit/shop_cubit.dart';
import 'package:flutter_application_1/features/shop/presentation/pages/shop_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('fa', 'IR'),
    supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
  });

  tearDown(() async => sl.reset());

  test('Single subscription product is configured at 99,000 Tomans', () {
    final purchase = MockPurchaseService(sl<StorageService>());
    expect(purchase.availableProducts.length, equals(1));
    final product = purchase.availableProducts.first;
    expect(product.id, equals('season_1_bundle'));
    expect(product.priceToman, equals(99000));
    expect(product.titleFa, contains('اشتراک طلایی'));
    expect(product.descriptionFa, contains('سرقت بزرگ'));
  });

  test('Storage correctly locks Heist and full packs until subscribed', () async {
    final storage = sl<StorageService>();
    expect(storage.isSubscribed, isFalse);
    expect(storage.isHeistUnlocked, isFalse);
    expect(storage.isPackPurchased('heist'), isFalse);
    expect(storage.isPackPurchased('pack_taboo_full'), isFalse);

    // Purchase subscription
    await storage.addPurchasedPack('season_1_bundle');
    expect(storage.isSubscribed, isTrue);
    expect(storage.isHeistUnlocked, isTrue);
    expect(storage.isPackPurchased('heist'), isTrue);
    expect(storage.isPackPurchased('pack_taboo_full'), isTrue);
    expect(storage.isPackPurchased('pack_bomb_full'), isTrue);
    expect(storage.isPackPurchased('pack_charades_full'), isTrue);
    expect(storage.isPackPurchased('pack_five_full'), isTrue);
    expect(storage.isPackPurchased('pack_drawing_full'), isTrue);
  });

  test('ContentService loads 400 free cards without subscription and 800 cards with subscription', () async {
    final storage = sl<StorageService>();
    final content = ContentService(storage);

    final freeCards = await content.load('taboo');
    expect(freeCards.length, equals(400));

    await storage.addPurchasedPack('season_1_bundle');
    final allCards = await content.load('taboo');
    expect(allCards.length, equals(800));
  });

  test('Router routes to HeistLockedPage when not subscribed and HeistGamePage when subscribed', () {
    final storage = sl<StorageService>();

    // Without subscription
    final lockedRoute = AppRouter.onGenerateRoute(const RouteSettings(name: '/prepare/heist'));
    expect(lockedRoute, isNotNull);
    expect(lockedRoute, isA<MaterialPageRoute>());

    // With subscription
    storage.addPurchasedPack('season_1_bundle');
    final unlockedRoute = AppRouter.onGenerateRoute(const RouteSettings(name: '/prepare/heist'));
    expect(unlockedRoute, isNotNull);
    expect(unlockedRoute, isA<MaterialPageRoute>());
  });

  testWidgets('ShopPage displays 99,000 Tomans subscription with buy action', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = sl<StorageService>();
    final purchase = MockPurchaseService(storage);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ShopCubit(purchase),
        child: app(const ShopPage()),
      ),
    );
    await tester.pump();

    expect(find.text('اشتراک طلایی جمعمون جمعه'), findsWidgets);
    expect(find.textContaining('۹۹٬۰۰۰ تومان'), findsWidgets);
    expect(find.textContaining('سرقت بزرگ'), findsWidgets);
    expect(find.text('خرید اشتراک (۹۹٬۰۰۰ تومان)'), findsOneWidget);

    // Scroll to and tap buy
    final buyButton = find.text('خرید اشتراک (۹۹٬۰۰۰ تومان)');
    await tester.ensureVisible(buyButton);
    await tester.pumpAndSettle();
    await tester.tap(buyButton);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Now subscription should be active
    expect(storage.isSubscribed, isTrue);
    expect(storage.isHeistUnlocked, isTrue);
    expect(find.text('اشتراک شما فعال است'), findsOneWidget);
  });

  testWidgets('HomePage shows locked indicator for Heist when unsubscribed', (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(app(const HomePage()));
    await tester.pump();

    expect(find.text('اشتراک طلایی'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ویژه اشتراک'), 200);
    expect(find.text('ویژه اشتراک'), findsOneWidget);
  });
}
