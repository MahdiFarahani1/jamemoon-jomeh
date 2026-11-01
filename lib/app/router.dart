import 'package:flutter/material.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/teams/presentation/pages/teams_setup_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/shop/presentation/pages/shop_page.dart';
import '../features/tournament/presentation/pages/tournament_lobby_page.dart';
import '../features/tournament/presentation/pages/tournament_podium_page.dart';
import '../features/taboo/presentation/pages/taboo_game_page.dart';
import '../features/hot_potato/presentation/pages/hot_potato_game_page.dart';
import '../features/charades/presentation/pages/charades_game_page.dart';
import '../features/five_seconds/presentation/pages/five_seconds_game_page.dart';
import '../features/drawing/presentation/pages/drawing_game_page.dart';
import '../features/extras/lucky_wheel/pages/lucky_wheel_page.dart';
import '../features/extras/random_picker/pages/random_picker_page.dart';
import '../features/extras/custom_cards/pages/custom_cards_page.dart';

// Named routing configuration for Jam'emoon Jomeh!
class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final args = (settings.arguments as Map<String, dynamic>?) ?? {};

    Widget page;

    switch (uri.path) {
      case '/':
        page = const SplashPage();
        break;
      case '/home':
        page = const HomePage();
        break;
      case '/teams':
        page = const TeamsSetupPage();
        break;
      case '/settings':
        page = const SettingsPage();
        break;
      case '/shop':
        page = const ShopPage();
        break;
      case '/tournament':
        page = const TournamentLobbyPage();
        break;
      case '/tournament/podium':
        page = const TournamentPodiumPage();
        break;
      case '/game/taboo':
        page = TabooGamePage(isQuickMode: args['isQuickMode'] ?? false);
        break;
      case '/game/hot_potato':
        page = HotPotatoGamePage(isQuickMode: args['isQuickMode'] ?? false);
        break;
      case '/game/charades':
        page = CharadesGamePage(isQuickMode: args['isQuickMode'] ?? false);
        break;
      case '/game/five_seconds':
        page = FiveSecondsGamePage(isQuickMode: args['isQuickMode'] ?? false);
        break;
      case '/game/drawing':
        page = DrawingGamePage(isQuickMode: args['isQuickMode'] ?? false);
        break;
      case '/extras/wheel':
        page = const LuckyWheelPage();
        break;
      case '/extras/picker':
        page = const RandomPickerPage();
        break;
      case '/extras/custom-cards':
        page = const CustomCardsPage();
        break;
      default:
        page = const HomePage();
        break;
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => page,
    );
  }
}

