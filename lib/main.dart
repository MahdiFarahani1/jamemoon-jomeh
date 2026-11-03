import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set portrait orientation for responsive mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set immersive dark UI overlay styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF111522),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize all services and dependencies
  await initDependencies();

  runApp(const JamemoonJomehApp());
}
