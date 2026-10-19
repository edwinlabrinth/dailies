import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // `?demo` — e.g. http://localhost:8080/?demo — boots with sample habits so
  // the app can be shown off without entering anything by hand.
  final demoMode = Uri.base.queryParameters.containsKey('demo');

  runApp(DailiesApp(demoMode: demoMode));
}

/// The Dailies habit tracker app.
class DailiesApp extends StatelessWidget {
  const DailiesApp({super.key, this.demoMode = false});

  /// When true the home screen is seeded with sample habits (see
  /// `data/demo_habits.dart`) and never writes to storage.
  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dailies — Level Up Daily',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(demoMode: demoMode),
    );
  }
}
