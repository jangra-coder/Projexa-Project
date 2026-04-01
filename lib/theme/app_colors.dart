import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color gradientStart = Color(0xFF2ECAC4);
  static const Color gradientMiddle = Color(0xFF1A9EBF);
  static const Color gradientEnd = Color(0xFF0A5CB8);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Colors.white;
  static const Color lightCardBg = Colors.white;
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightSubtext = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightInputBg = Color(0xFFF3F4F6);
  static const Color lightInputBorder = Color(0xFFD1D5DB);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0D1B2A);
  static const Color darkSurface = Color(0xFF1B2838);
  static const Color darkCardBg = Color(0xFF1B3A4B);
  static const Color darkText = Color(0xFFE0E6ED);
  static const Color darkSubtext = Color(0xFF8899A6);
  static const Color darkDivider = Color(0xFF2A3F55);
  static const Color darkInputBg = Color(0xFF162635);
  static const Color darkInputBorder = Color(0xFF2A4A5F);

  // Accent colors
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentTeal = Color(0xFF26C6DA);

  // Status colors
  static const Color activeGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color expiredRed = Color(0xFFEF4444);
  static const Color dangerRed = Color(0xFFDC2626);

  // Bottom nav
  static const Color navDarkBg = Color(0xFF0F2030);
  static const Color navLightBg = Colors.white;
  static const Color navActiveIcon = Color(0xFF26C6DA);
  static const Color navInactiveIcon = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF26C6DA), Color(0xFF2196F3)],
  );

  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6FB5), Color(0xFF2196F3), Color(0xFF26C6DA)],
  );

  // Status gradients for profile cards
  static const LinearGradient activeGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );

  static const LinearGradient expiredGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );
}
