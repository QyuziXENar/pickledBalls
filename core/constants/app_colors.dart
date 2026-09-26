// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

/// Centralized universal arcade palette and design tokens for Paddle Blitz 3.0.
class AppColors {
  AppColors._();

  // --------------------------------------------------------------------------
  // PRIMARY ARCADE HIGHLIGHTS
  // --------------------------------------------------------------------------
  static const Color opticYellow = Color(0xFFD6F800);
  static const Color cyberCyan = Color(0xFF00E5FF);
  static const Color electricCyan = cyberCyan;
  static const Color mintAccent = Color(0xFF26E098);
  static const Color electricCoral = Color(0xFFFF5252);
  static const Color crimson = electricCoral;

  // --------------------------------------------------------------------------
  // BACKGROUND & DEEP SURFACES
  // --------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF070B0E);
  static const Color darkCard = Color(0xFF0F1824);
  static const Color darkSurface = Color(0xFF0C1613);
  static const Color deepGreen = Color(0xFF0A2920);

  // --------------------------------------------------------------------------
  // TYPOGRAPHY TOKENS
  // --------------------------------------------------------------------------
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8BA59B);
  static const Color textSubtle = Color(0xFF5A756B);

  // --------------------------------------------------------------------------
  // TRI-CURRENCY DESIGN TOKENS (Dual-name support)
  // --------------------------------------------------------------------------
  // Gold Coins (Soft Currency)
  static const Color coinGold = Color(0xFFFFD54F);
  static const Color goldCoins = coinGold;
  static const Color coinGoldDark = Color(0xFFFFA000);
  static const Color goldCoinsDark = coinGoldDark;

  // Diamonds (Hard Premium Currency)
  static const Color gemDiamond = Color(0xFF4FC3F7);
  static const Color diamonds = gemDiamond;
  static const Color gemDiamondDark = Color(0xFF0288D1);
  static const Color diamondsDark = gemDiamondDark;

  // Upgrade Points (UP) (RPG Level-Up Progression)
  static const Color upgradePoint = Color(0xFFE040FB);
  static const Color upgradePoints = upgradePoint;
  static const Color upgradePointDark = Color(0xFF7B1FA2);
  static const Color upgradePointsDark = upgradePointDark;

  // --------------------------------------------------------------------------
  // GLASSMORPHISM SURFACES & BORDERS
  // --------------------------------------------------------------------------
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBorderStrong = Color(0x66FFFFFF);

  // --------------------------------------------------------------------------
  // 4 ATHLETE SIGNATURE THEMING
  // --------------------------------------------------------------------------
  // Aria Vance (Speedster)
  static const Color ariaBody = Color(0xFF00B4D8);
  static const Color ariaAccent = Color(0xFF90E0EF);

  // Marcus Stone (Powerhouse)
  static const Color marcusBody = Color(0xFFE63946);
  static const Color marcusAccent = Color(0xFFFFB703);

  // Elena Cruz (Tactician)
  static const Color elenaBody = Color(0xFF7209B7);
  static const Color elenaAccent = Color(0xFFF72585);

  // Jax Cooper (All-Rounder)
  static const Color jaxBody = Color(0xFF2A9D8F);
  static const Color jaxAccent = Color(0xFFE9C46A);

  // --------------------------------------------------------------------------
  // UNIVERSAL GRADIENTS
  // --------------------------------------------------------------------------
  static const LinearGradient battleButtonGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFA000), Color(0xFFFF6F00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lanHostGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0288D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient upgradePointGradient = LinearGradient(
    colors: [Color(0xFFEA80FC), Color(0xFFE040FB), Color(0xFFAA00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}