// lib/services/orientation_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppOrientationMode {
  portrait,
  landscape,
}

class OrientationService {
  OrientationService._();

  static AppOrientationMode _currentMode = AppOrientationMode.portrait;
  static AppOrientationMode get currentMode => _currentMode;

  /// Applies the orientation mode directly to hardware system channels.
  static Future<void> applyOrientation(AppOrientationMode mode) async {
    _currentMode = mode;
    if (mode == AppOrientationMode.portrait) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  static Future<void> lockPortrait() => applyOrientation(AppOrientationMode.portrait);
  static Future<void> lockLandscape() => applyOrientation(AppOrientationMode.landscape);

  /// Helper utility to test if the active context is running in landscape.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}