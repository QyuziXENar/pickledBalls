// lib/main.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'models/game_state.dart';
import 'screens/opening/company_intro_screen.dart';
import 'widgets/asset_helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Android & iOS Edge-to-Edge Navigation
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 2. iOS Ambient Audio Configuration
  try {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  } catch (e) {
    debugPrint('Audio context configuration notice: $e');
  }

  // 3. Initialize Zero-Crash Asset Manifest Index
  await AppAssetRegistry.init();

  // 4. Load Saved Disk State
  await GameState.instance.loadFromStorage();

  runApp(const PaddleBlitzApp());
}

class PaddleBlitzApp extends StatelessWidget {
  const PaddleBlitzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paddle Blitz 3.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.opticYellow,
          secondary: AppColors.mintAccent,
          surface: AppColors.darkSurface,
        ),
      ),
      home: const CompanyIntroScreen(),
    );
  }
}