import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/taboo/presentation/pages/taboo_game_page.dart';
import 'package:flutter_application_1/features/tournament/presentation/cubit/tournament_cubit.dart';
import 'package:flutter_application_1/features/tournament/presentation/pages/tournament_lobby_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({
      'sound_enabled': false,
      'music_enabled': false,
    });
    await initDependencies();
  });

  tearDown(() async => sl.reset());

  testWidgets('tournament opens first and uses the app team state', (
    tester,
  ) async {
    await tester.pumpWidget(const JamemoonJomehApp());
    await tester.pumpAndSettle();
    final button = find.text('بزن بریم برای جام!');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(TournamentLobbyPage), findsOneWidget);
    expect(find.text('جام پنجگانه'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(TournamentLobbyPage));
    final teams = context.read<TeamsCubit>();
    final tournament = context.read<TournamentCubit>();
    final teamId = teams.state.teams.first.id;
    teams.updateTeamScore(teamId, 5);
    expect(teams.state.teams.first.score, 5);
    tournament.startTournament();
    await tester.pump();
    expect(teams.state.teams.first.score, 0);
    expect(tournament.state.teams.first.score, 0);
    expect(find.textContaining('شروع رقابت در'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('شروع رقابت در'));
    await tester.tap(find.textContaining('شروع رقابت در'));
    await tester.pumpAndSettle();
    expect(find.byType(TabooGamePage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
