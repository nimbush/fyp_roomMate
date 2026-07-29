import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8C61);
  static const Color primaryDark = Color(0xFFE5521A);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFFAAAAAA);

  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFDDDDDD);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  static const Color likeGreen = Color(0xFF4CAF50);
  static const Color passRed = Color(0xFFFF5252);

  static const Color chatBubbleSent = Color(0xFFFF6B35);
  static const Color chatBubbleReceived = Color(0xFFF0F0F0);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
