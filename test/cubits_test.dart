import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/core/widgets/team_identity.dart';
import 'package:flutter_application_1/core/models/team_model.dart';
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

    test('keeps only the two existing saved teams', () {
      storage.saveTeams([
        const Team(id: 'first', name: 'اول', colorValue: 0xFF123456).toJson(),
        const Team(id: 'second', name: 'دوم', colorValue: 0xFF654321).toJson(),
        const Team(id: 'third', name: 'سوم', colorValue: 0xFF123456).toJson(),
      ]);
      final cubit = TeamsCubit(storage);
      expect(cubit.state.teams.length, equals(2));
      expect(cubit.state.teams.map((team) => team.id), ['first', 'second']);
      expect(storage.getSavedTeams(), hasLength(2));
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
      cubit.updateTeam(
        teamId,
        name: 'تیم تازه',
        colorValue: 0xFF26C6DA,
        iconKey: 'rocket',
      );
      expect(cubit.state.teams.first.colorValue, 0xFF26C6DA);
      expect(cubit.state.teams.first.name, 'تیم تازه');
      expect(cubit.state.teams.first.iconKey, 'rocket');
      final restored = TeamsCubit(storage);
      expect(restored.state.teams.first.colorValue, 0xFF26C6DA);
      expect(restored.state.teams.first.name, 'تیم تازه');
      expect(restored.state.teams.first.iconKey, 'rocket');
    });

    test('supports rich expanded palette and icons with persistence', () {
      expect(AppColors.teamPalette.length, greaterThanOrEqualTo(20));
      expect(TeamIcons.options.length, greaterThanOrEqualTo(25));

      final iconKeys = TeamIcons.options.map((o) => o.key).toSet();
      expect(iconKeys.length, equals(TeamIcons.options.length));

      for (final option in TeamIcons.options) {
        expect(option.key.trim(), isNotEmpty);
        expect(option.label.trim(), isNotEmpty);
        expect(TeamIcons.forKey(option.key), equals(option.icon));
      }

      final cubit = TeamsCubit(storage);
      final newColor = AppColors.teamPalette.last.toARGB32();
      const newIcon = 'trophy';
      cubit.updateTeam(
        cubit.state.teams.first.id,
        name: cubit.state.teams.first.name,
        colorValue: newColor,
        iconKey: newIcon,
      );
      expect(cubit.state.teams.first.colorValue, newColor);
      expect(cubit.state.teams.first.iconKey, newIcon);
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
    test(
      'Loads single 99k subscription product and handles purchase flow',
      () async {
        final cubit = ShopCubit(purchase);
        expect(cubit.state.products.length, equals(1));
        expect(cubit.state.products.first.priceToman, equals(99000));
        expect(cubit.state.products.first.id, equals('season_1_bundle'));
        expect(cubit.state.purchasedIds.isEmpty, isTrue);

        final success = await cubit.buy('season_1_bundle');
        expect(success, isTrue);
        expect(cubit.state.purchasedIds.contains('season_1_bundle'), isTrue);
        expect(storage.isPackPurchased('season_1_bundle'), isTrue);
        expect(storage.isPackPurchased('heist'), isTrue);
        expect(storage.isPackPurchased('pack_taboo_full'), isTrue);
        expect(storage.isPackPurchased('pack_bomb_full'), isTrue);
        expect(storage.isPackPurchased('pack_charades_full'), isTrue);
      },
    );

    test('Subscription unlocks all packs and heist game', () async {
      final cubit = ShopCubit(purchase);
      final success = await cubit.buy('season_1_bundle');
      expect(success, isTrue);
      expect(storage.isPackPurchased('heist'), isTrue);
      expect(storage.isPackPurchased('pack_bomb_full'), isTrue);
      expect(storage.isPackPurchased('pack_charades_full'), isTrue);
      expect(storage.isPackPurchased('pack_five_full'), isTrue);
      expect(storage.isPackPurchased('pack_drawing_full'), isTrue);
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
