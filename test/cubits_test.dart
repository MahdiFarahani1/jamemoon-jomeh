import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/core/services/purchase_service.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter_application_1/features/shop/presentation/cubit/shop_cubit.dart';
import 'package:flutter_application_1/features/tournament/presentation/cubit/tournament_cubit.dart';

void main() {
  late SharedPreferences prefs;
  late StorageService storage;
  late PurchaseService purchase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    purchase = MockPurchaseService(storage);
  });

  group('TeamsCubit Tests', () {
    test('Initializes with 2 default teams', () {
      final cubit = TeamsCubit(storage);
      expect(cubit.state.teams.length, equals(2));
      expect(cubit.state.teams[0].name, contains('پلنگ'));
    });

    test('Adds and removes a team correctly', () {
      final cubit = TeamsCubit(storage);
      cubit.addTeam(name: 'تیم شاهین', colorValue: 0xFF123456);
      expect(cubit.state.teams.length, equals(3));
      final addedTeam = cubit.state.teams.last;
      expect(addedTeam.name, equals('تیم شاهین'));

      cubit.removeTeam(addedTeam.id);
      expect(cubit.state.teams.length, equals(2));
    });

    test('rapidly added players retain distinct identities', () {
      final cubit = TeamsCubit(storage);
      final teamId = cubit.state.teams.first.id;
      for (var i = 0; i < 20; i++) {
        cubit.addPlayer(name: 'بازیکن $i', teamId: teamId);
      }
      expect(cubit.state.players.map((player) => player.id).toSet().length, 20);
    });

    test('team color and icon remain saved', () {
      final cubit = TeamsCubit(storage);
      final teamId = cubit.state.teams.first.id;
      cubit.updateTeamAppearance(
        teamId,
        colorValue: 0xFF26C6DA,
        iconKey: 'rocket',
      );
      expect(cubit.state.teams.first.colorValue, 0xFF26C6DA);
      expect(cubit.state.teams.first.iconKey, 'rocket');
      final restored = TeamsCubit(storage);
      expect(restored.state.teams.first.colorValue, 0xFF26C6DA);
      expect(restored.state.teams.first.iconKey, 'rocket');
    });

    test('Adds a player and updates scores', () {
      final cubit = TeamsCubit(storage);
      cubit.addPlayer(name: 'سهراب', teamId: cubit.state.teams.first.id);
      expect(cubit.state.players.length, equals(1));
      expect(cubit.state.players.first.name, equals('سهراب'));

      final teamId = cubit.state.teams.first.id;
      cubit.updateTeamScore(teamId, 10);
      expect(cubit.state.teams.first.score, equals(10));

      cubit.resetAllScores();
      expect(cubit.state.teams.first.score, equals(0));
    });
  });

  group('SettingsCubit Tests', () {
    test('Toggles sound and vibration properly', () async {
      final cubit = SettingsCubit(storage);
      expect(cubit.state.soundEnabled, isTrue);
      expect(cubit.state.vibrationEnabled, isTrue);

      await cubit.toggleSound();
      expect(cubit.state.soundEnabled, isFalse);
      expect(storage.isSoundEnabled, isFalse);

      await cubit.toggleVibration();
      expect(cubit.state.vibrationEnabled, isFalse);
      expect(storage.isVibrationEnabled, isFalse);
    });
  });

  group('ShopCubit Tests', () {
    test('Loads 6 products and handles purchase flow', () async {
      final cubit = ShopCubit(purchase);
      expect(cubit.state.products.length, equals(6));
      expect(cubit.state.purchasedIds.isEmpty, isTrue);

      final success = await cubit.buy('pack_taboo_full');
      expect(success, isTrue);
      expect(cubit.state.purchasedIds.contains('pack_taboo_full'), isTrue);
      expect(storage.isPackPurchased('pack_taboo_full'), isTrue);
    });

    test('Season 1 bundle unlocks all packs', () async {
      final cubit = ShopCubit(purchase);
      final success = await cubit.buy('season_1_bundle');
      expect(success, isTrue);
      expect(storage.isPackPurchased('pack_bomb_full'), isTrue);
      expect(storage.isPackPurchased('pack_charades_full'), isTrue);
    });
  });

  group('TournamentCubit Tests', () {
    test('Progresses through 5 stages and finishes tournament', () {
      final teamsCubit = TeamsCubit(storage);
      final tournamentCubit = TournamentCubit(
        storageService: storage,
        teamsCubit: teamsCubit,
      );

      expect(tournamentCubit.state.currentStageIndex, equals(0));
      expect(tournamentCubit.state.isFinished, isFalse);

      // Complete all 5 stages
      for (int i = 0; i < 5; i++) {
        tournamentCubit.completeCurrentStage();
      }

      expect(tournamentCubit.state.isFinished, isTrue);
    });
  });
}
