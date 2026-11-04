import '../features/decoder/presentation/pages/decoder_game_page.dart';
import '../features/heist/presentation/pages/heist_game_page.dart';
import '../features/heist/presentation/pages/heist_locked_page.dart';
import '../features/extras/party_challenges/party_challenges_page.dart';
import '../features/teams/presentation/pages/game_preparation_page.dart';
import '../core/models/game_setup_config.dart';

import 'package:flutter/material.dart';

import 'di/service_locator.dart';
import '../core/services/storage_service.dart';
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
import '../features/extras/random_picker/pages/random_picker_page.dart';
import '../features/extras/custom_cards/pages/custom_cards_page.dart';

// Named routing configuration for Jam'emoon Jomeh!
class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final args = (settings.arguments as Map<String, dynamic>?) ?? {};
    final resume = args['resume'] == true || args['resumeSaved'] == true;
    final savedSession = resume && uri.path.startsWith('/game/')
        ? sl<StorageService>().getGameSession(uri.path.split('/').last)
        : null;
    final gameKey = uri.path.split('/').last;
    final setup = GameSetupConfig.fromArguments(gameKey, {
      ...args,
      if (savedSession?['roundSeconds'] != null)
        'roundSeconds': savedSession!['roundSeconds'],
      if (savedSession?['totalRounds'] != null)
        'totalRounds': savedSession!['totalRounds'],
      if (savedSession?['participationMode'] != null)
        'participationMode': savedSession!['participationMode'],
      if (savedSession?['charadesCategory'] != null)
        'charadesCategory': savedSession!['charadesCategory'],
    });

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
      case '/game/decoder':
        page = DecoderGamePage(resumeSaved: resume);
        break;
      case '/prepare/heist':
        page = sl<StorageService>().isPackPurchased('heist')
            ? const HeistGamePage()
            : const HeistLockedPage();
        break;
      case '/game/heist':
        page = sl<StorageService>().isPackPurchased('heist')
            ? HeistGamePage(resumeSaved: resume)
            : const HeistLockedPage();
        break;
      case '/prepare/taboo':
      case '/prepare/hot_potato':
      case '/prepare/charades':
      case '/prepare/five_seconds':
      case '/prepare/drawing':
      case '/prepare/decoder':
        page = GamePreparationPage(gameKey: gameKey);
        break;
      case '/game/taboo':
        page = TabooGamePage(
          setup: setup,
          resumeSaved: args['resume'] == true || args['resumeSaved'] == true,
        );
        break;
      case '/game/hot_potato':
        page = HotPotatoGamePage(
          setup: setup,
          resumeSaved: args['resume'] == true || args['resumeSaved'] == true,
        );
        break;
      case '/game/charades':
        page = CharadesGamePage(
          setup: setup,
          resumeSaved: args['resume'] == true || args['resumeSaved'] == true,
        );
        break;
      case '/game/five_seconds':
        page = FiveSecondsGamePage(
          setup: setup,
          resumeSaved: args['resume'] == true || args['resumeSaved'] == true,
        );
        break;
      case '/game/drawing':
        page = DrawingGamePage(
          setup: setup,
          resumeSaved: args['resume'] == true || args['resumeSaved'] == true,
        );
        break;
      case '/extras/challenges':
        page = const PartyChallengesPage();
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

    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}
