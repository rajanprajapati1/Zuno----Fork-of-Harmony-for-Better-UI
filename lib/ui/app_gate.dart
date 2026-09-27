import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'home.dart';
import 'screens/Auth/login_screen.dart';
import 'screens/Movies/movie_home.dart';

/// Entry route ('/'). Picks the first screen from the saved session:
///   not logged in            -> LoginScreen
///   appMode == 'movies'      -> MovieHome
///   otherwise (music or none) -> music Home
///
/// Login, mode selection and "switch mode" all finish with
/// `Get.offAllNamed('/')`, which rebuilds this gate with the new state.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Hive.box('AppPrefs');
    if (prefs.get('isLoggedIn') != true) return const LoginScreen();
    return switch (prefs.get('appMode')) {
      'movies' => const MovieHome(),
      // no mode picked yet: open Music (Movies is one tap away in Settings)
      _ => const Home(),
    };
  }
}
