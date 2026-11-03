import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/teams/presentation/pages/game_preparation_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TeamsCubit teams;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    teams = TeamsCubit(StorageService(await SharedPreferences.getInstance()));
  });
  tearDown(() => teams.close());

  Widget app(String key, ValueChanged<RouteSettings> onRoute) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
    home: BlocProvider.value(
      value: teams,
      child: GamePreparationPage(gameKey: key),
    ),
    onGenerateRoute: (settings) {
      onRoute(settings);
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('game started')),
      );
    },
  );

  testWidgets('timed game requires members and sends chosen rules', (
    tester,
  ) async {
    RouteSettings? launched;
    await tester.pumpWidget(app('taboo', (settings) => launched = settings));
    expect(find.text('زمان هر نوبت'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('شروع بازی'), 250);
    await tester.tap(find.text('شروع بازی'));
    await tester.pump();
    expect(launched, isNull);
    expect(find.textContaining('عضو نیاز دارد'), findsOneWidget);

    for (final team in teams.state.teams) {
      teams.addPlayer(name: 'عضو یک', teamId: team.id);
      teams.addPlayer(name: 'عضو دو', teamId: team.id);
    }
    await tester.pump();
    await tester.scrollUntilVisible(find.text('90 ثانیه'), -250);
    await tester.tap(find.text('90 ثانیه'));
    await tester.pump();
    await tester.tap(find.text('7 دور'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('شروع بازی'), 250);
    await tester.tap(find.text('شروع بازی'));
    await tester.pump();
    expect(launched?.name, '/game/taboo');
    expect(launched?.arguments, {'roundSeconds': 90, 'totalRounds': 7});
  });

  testWidgets('untimed bomb setup exposes rounds without round clock', (
    tester,
  ) async {
    await tester.pumpWidget(app('hot_potato', (_) {}));
    expect(find.text('زمان هر نوبت'), findsNothing);
    expect(find.text('3 دور'), findsOneWidget);
  });

  testWidgets(
    'adding a member closes the dialog without disposing dependencies early',
    (tester) async {
      await tester.pumpWidget(app('taboo', (_) {}));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
      await tester.pump();
      await tester.tap(find.text('عضو').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'مهسا');
      await tester.tap(find.text('افزودن'));
      await tester.pumpAndSettle();
      expect(teams.state.players.single.name, 'مهسا');
      expect(find.text('مهسا'), findsOneWidget);
      await tester.tap(find.text('عضو').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'رضا');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(teams.state.players.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected time and round have readable contrast', (tester) async {
    await tester.pumpWidget(app('taboo', (_) {}));
    final selected = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text('60 ثانیه'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(selected.selected, isTrue);
    expect(selected.selectedColor, AppColors.accent);
    expect(selected.labelStyle?.color, AppColors.background);
    expect(selected.checkmarkColor, AppColors.background);
    await tester.tap(find.text('45 ثانیه'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(
            find.ancestor(
              of: find.text('45 ثانیه'),
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('team color and icon can be changed from game preparation', (
    tester,
  ) async {
    await tester.pumpWidget(app('taboo', (_) {}));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await tester.pump();
    await tester.tap(find.byTooltip('رنگ و نشان تیم').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('رنگ شمارهٔ 4'));
    await tester.ensureVisible(find.text('موشک'));
    await tester.tap(find.text('موشک'));
    await tester.scrollUntilVisible(
      find.text('ذخیرهٔ ظاهر تیم'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('ذخیرهٔ ظاهر تیم'));
    await tester.pumpAndSettle();
    expect(
      teams.state.teams.first.colorValue,
      AppColors.teamPalette[3].toARGB32(),
    );
    expect(teams.state.teams.first.iconKey, 'rocket');
    expect(tester.takeException(), isNull);
  });
}
