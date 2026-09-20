import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'screens/company_intro_screen.dart';
import 'widgets/ambient_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved levels, XP, unlocked paddles, and settings from phone disk
  await GameState.instance.loadFromStorage();

  runApp(const PaddleBlitzApp());
}

class PaddleBlitzApp extends StatelessWidget {
  const PaddleBlitzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paddle Blitz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.darkBg,
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.opticYellow,
          secondary: AppTheme.mintAccent,
          surface: AppTheme.deepGreen,
        ),
      ),
      home: const CompanyIntroScreen(),
    );
  }
}