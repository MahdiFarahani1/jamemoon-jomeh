import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
  });

  testWidgets('App launches successfully to Splash page with Jamemoon Jomeh title', (tester) async {
    await tester.pumpWidget(const JamemoonJomehApp());
    await tester.pump();

    // Verify Persian title exists
    expect(find.text('جمعمون جمعه!'), findsOneWidget);

    // Pump past the splash delay to settle all timers
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // After splash, verify Home page title exists
    expect(find.text('جمعمون جمعه!'), findsOneWidget);
  });
}
