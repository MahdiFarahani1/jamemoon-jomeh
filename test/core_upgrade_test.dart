import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/models/game_mode.dart';
import 'package:flutter_application_1/core/models/player_model.dart';
import 'package:flutter_application_1/core/services/purchase_service.dart';
import 'package:flutter_application_1/core/services/bazaar_purchase_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/core/utils/ranking.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/tournament/presentation/cubit/tournament_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
  });

  group('Storage upgrade contracts', () {
    test(
      'writes are immediately readable and survive a new service instance',
      () async {
        final first = storage.saveGameSession('taboo', {'round': 3});
        final second = storage.saveGameSession('taboo', {'round': 4});
        expect(storage.getGameSession('taboo'), {'round': 4});
        await Future.wait([first, second]);

        expect(StorageService(prefs).getGameSession('taboo'), {'round': 4});
      },
    );

    test(
      'decoder convenience methods alias the decoder game session',
      () async {
        await storage.saveActiveDecoder({
          'version': 1,
          'sessionId': 'decoder-a',
        });

        expect(storage.getGameSession('decoder'), storage.getActiveDecoder());
        expect(storage.getActiveDecoder(), {
          'version': 1,
          'sessionId': 'decoder-a',
        });
        await storage.saveGameSession('decoder', {
          'version': 1,
          'sessionId': 'decoder-b',
        });
        expect(storage.getActiveDecoder()?['sessionId'], 'decoder-b');
      },
    );

    test(
      'corrupt and structurally invalid saved payloads return empty values',
      () async {
        await prefs.setString('saved_teams', '{broken json');
        await prefs.setString('saved_players', '{"not":"a list"}');
        await prefs.setString('active_tournament', '[]');
        await prefs.setString('game_session_decoder', 'null');
        await prefs.setString('custom_cards', '[1, null, {"ok": true}]');

        final corruptedStorage = StorageService(prefs);
        expect(corruptedStorage.getSavedTeams(), isEmpty);
        expect(corruptedStorage.getSavedPlayers(), isEmpty);
        expect(corruptedStorage.getActiveTournament(), isNull);
        expect(corruptedStorage.getActiveDecoder(), isNull);
        expect(corruptedStorage.getCustomCards(), [
          {'ok': true},
        ]);
      },
    );

    test(
      'clearAll retains purchased packs and unrelated preferences',
      () async {
        await storage.addPurchasedPack('pack_taboo_full');
        await prefs.setString('unrelated_preference', 'keep me');
        await storage.saveGameSession('charades', {'round': 2});
        await storage.saveTeams([
          {'id': 'team-a'},
        ]);

        await storage.clearAll();

        expect(storage.purchasedPacks, ['pack_taboo_full']);
        expect(prefs.getString('unrelated_preference'), 'keep me');
        expect(storage.getGameSession('charades'), isNull);
        expect(storage.getSavedTeams(), isEmpty);
      },
    );

    test(
      'season-one product IDs and heist are unlocked by the bundle',
      () async {
        await storage.addPurchasedPack('season_1_bundle');
        for (final id in StorageService.seasonOnePackIds) {
          expect(storage.isPackPurchased(id), isTrue, reason: id);
        }
        expect(storage.isPackPurchased('heist'), isTrue);
        expect(storage.isPackPurchased('pack_future_game_full'), isFalse);
        expect(storage.isPackPurchased('season_2_bundle'), isFalse);
      },
    );

    test(
      'game results are idempotent by session and bounded to 200 records',
      () async {
        await storage.recordGameResult(
          sessionId: 'same-session',
          gameKey: 'taboo',
          scores: {'A': 3},
        );
        await storage.recordGameResult(
          sessionId: 'same-session',
          gameKey: 'taboo',
          scores: {'A': 99},
        );
        expect(storage.getGameHistory(), hasLength(1));
        expect(storage.getGameHistory().single['scores'], {'A': 3});

        for (var i = 0; i < 205; i++) {
          await storage.recordGameResult(
            sessionId: 'session-$i',
            gameKey: 'taboo',
            scores: {'A': i},
          );
        }
        expect(storage.getGameHistory(), hasLength(200));
        expect(
          storage.getGameHistory().any(
            (row) => row['sessionId'] == 'session-204',
          ),
          isTrue,
        );
      },
    );
  });

  test('dense ranking gives the next distinct score rank two after ties', () {
    expect(denseRanks([100, 100, 100, 100, 70, 70, 10]), [1, 1, 1, 1, 2, 2, 3]);
  });

  group('Shared model and catalog contracts', () {
    test('Player.copyWith can explicitly clear a nullable team assignment', () {
      const player = Player(id: 'p1', name: 'Player', teamId: 'team-a');
      expect(player.copyWith(teamId: null).teamId, isNull);
      expect(player.copyWith().teamId, 'team-a');
    });

    test(
      'catalog has seven games while tournament has its five ordered stages',
      () {
        expect(GameInfo.allGames, hasLength(7));
        expect(GameInfo.allGames.last.key, 'heist');
        expect(GameInfo.tournamentGames, hasLength(5));
        expect(GameInfo.tournamentGames.map((game) => game.key), [
          'taboo',
          'hot_potato',
          'charades',
          'five_seconds',
          'drawing',
        ]);
      },
    );
  });

  group('Tournament persistence contracts', () {
    test(
      'five explicit stages complete once, and finished state cannot advance',
      () async {
        final teams = TeamsCubit(storage);
        final tournament = TournamentCubit(
          storageService: storage,
          teamsCubit: teams,
        );
        expect(tournament.state.stages, hasLength(5));

        tournament.startTournament();
        for (var stage = 0; stage < 5; stage++) {
          expect(tournament.state.currentStageIndex, stage);
          tournament.completeCurrentStage();
        }
        expect(tournament.state.isFinished, isTrue);
        expect(tournament.state.currentStageIndex, 4);
        tournament.completeCurrentStage();
        expect(tournament.state.isFinished, isTrue);
        expect(tournament.state.currentStageIndex, 4);
        await teams.close();
        await tournament.close();
      },
    );

    test('legacy tournament save restores its stage index', () async {
      await storage.saveActiveTournament({
        'currentStageIndex': 2,
        'isFinished': false,
      });
      final teams = TeamsCubit(storage);
      final tournament = TournamentCubit(
        storageService: storage,
        teamsCubit: teams,
      );

      expect(tournament.state.currentStageIndex, 2);
      expect(tournament.state.currentGame.key, 'charades');
      await teams.close();
      await tournament.close();
    });
  });

  group('Purchase safety', () {
    test(
      'local checkout is unavailable and mock rejects unknown SKUs',
      () async {
        final local = LocalPurchaseService(storage);
        final mock = MockPurchaseService(storage);

        expect(local.purchasesAvailable, isFalse);
        expect(await local.buyProduct('pack_taboo_full'), isFalse);
        expect(await mock.buyProduct('pack_future_game_full'), isFalse);
        expect(storage.purchasedPacks, isEmpty);
      },
    );

    test(
      'default dependency registration cannot fabricate a purchase',
      () async {
        await sl.reset();
        addTearDown(sl.reset);
        await initDependencies();

        final registered = sl<PurchaseService>();
        expect(registered, isA<BazaarPurchaseService>());
        expect(registered.purchasesAvailable, isTrue);
        expect(await registered.buyProduct('pack_taboo_full'), isFalse);
        expect(sl<StorageService>().purchasedPacks, isEmpty);
      },
    );
  });
}
