import 'package:material_ui/material_ui.dart';

/// Cassia Seed brand colours, taken directly from the approved prototype.
///
/// Light and dark variants are both defined so the app can support dark mode.
class AppColors {
  AppColors._(); // prevent instances; use like AppColors.green

  // --- Light theme ---
  static const Color background = Color(0xFFF6F2E9); // warm cream
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF22180F); // dark brown text
  static const Color muted = Color(0xFF7D6E5C); // secondary text
  static const Color green = Color(0xFF1F5A30); // primary brand green
  static const Color greenLight = Color(0xFF2F7A3F); // buttons / accents
  static const Color gold = Color(0xFFC9A24B); // highlight gold
  static const Color brown = Color(0xFF4A2F1B);
  static const Color line = Color(0xFFE9E0CF); // borders / dividers

  // --- Dark theme ---
  static const Color backgroundDark = Color(0xFF12100C);
  static const Color cardDark = Color(0xFF1D1913);
  static const Color inkDark = Color(0xFFF4ECDC);
  static const Color mutedDark = Color(0xFFB3A58F);
  static const Color greenDark = Color(0xFF4CAE62);
  static const Color goldDark = Color(0xFFE2BD62);
  static const Color lineDark = Color(0xFF322B20);
}
