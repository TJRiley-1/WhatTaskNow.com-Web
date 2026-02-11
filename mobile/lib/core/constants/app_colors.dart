import 'dart:ui';

/// App color palette - indigo/amber with glassmorphism dark theme
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);

  // Primary - Indigo
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary - Amber
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFBBF24);

  // Glassmorphism
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Swipe feedback
  static const Color swipeAccept = Color(0xFF22C55E);
  static const Color swipeSkip = Color(0xFFEF4444);

  // Task type colors
  static const Map<String, Color> typeColors = {
    'Chores': Color(0xFF6366F1),
    'Work': Color(0xFF3B82F6),
    'Health': Color(0xFF22C55E),
    'Admin': Color(0xFF8B5CF6),
    'Errand': Color(0xFFF59E0B),
    'Self-care': Color(0xFFEC4899),
    'Creative': Color(0xFFF97316),
    'Social': Color(0xFF14B8A6),
  };

  static Color getTypeColor(String type) {
    return typeColors[type] ?? primary;
  }
}
