import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color emeraldGreen = Color(0xFF0F9D58);
  static const Color mintGreen = Color(0xFF2ECC71);
  static const Color darkEmerald = Color(0xFF0C7A44);
  static const Color amberGlow = Color(0xFFFFB300);
  static const Color orangeGlow = Color(0xFFE67E22);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0A0E17);
  static const Color darkBgGradientStart = Color(0xFF0A0E17);
  static const Color darkBgGradientEnd = Color(0xFF16222F);
  static const Color darkCardBg = Color(0x1F203042); // Glassmorphism container
  static const Color darkDialogBg = Color(0xFF182030); // Fully opaque dialog background
  static const Color darkCardBorder = Color(0x2A3A4D62);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Mode Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightBgGradientStart = Color(0xFFF8FAFC);
  static const Color lightBgGradientEnd = Color(0xFFE2E8F0);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Card background gradients
  static const Gradient activePrayerGradient = LinearGradient(
    colors: [emeraldGreen, darkEmerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkBackgroundGradient = LinearGradient(
    colors: [darkBgGradientStart, darkBgGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient lightBackgroundGradient = LinearGradient(
    colors: [lightBgGradientStart, lightBgGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
