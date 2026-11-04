import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'di/service_locator.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import '../core/services/storage_service.dart';
import '../core/services/purchase_service.dart';
import '../features/teams/presentation/cubit/teams_cubit.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/shop/presentation/cubit/shop_cubit.dart';
import '../features/tournament/presentation/cubit/tournament_cubit.dart';

// Root application widget with RTL Persian localization & Global Cubits
class JamemoonJomehApp extends StatelessWidget {
  const JamemoonJomehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TeamsCubit>(
          create: (_) => TeamsCubit(sl<StorageService>()),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(sl<StorageService>()),
        ),
        BlocProvider<ShopCubit>(
          create: (_) => ShopCubit(sl<PurchaseService>()),
        ),
        BlocProvider<TournamentCubit>(
          create: (context) => TournamentCubit(
            storageService: sl<StorageService>(),
            teamsCubit: context.read<TeamsCubit>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'جمعمون جمعه!',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/',
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
