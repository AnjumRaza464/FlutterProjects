import 'package:material_ui/material_ui.dart';

/// How a crop is drawn across the app: its emoji and its two-colour gradient
/// (light to deep), as in the approved design.
class CropStyle {
  const CropStyle(this.emoji, this.light, this.deep);

  final String emoji;
  final Color light;
  final Color deep;

  /// The crop's colour wash, used behind pack photos and on spotlight cards.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, deep],
      );

  static const _fallback = CropStyle('🌱', Color(0xFFA5D6A7), Color(0xFF2E7D32));

  // Checked in order: "bitter gourd" must be recognised before "gourd".
  static const _styles = [
    ('tomato', CropStyle('🍅', Color(0xFFFF8A65), Color(0xFFB71C1C))),
    ('chilli', CropStyle('🌶️', Color(0xFFE57373), Color(0xFF6D1414))),
    ('pepper', CropStyle('🌶️', Color(0xFFE57373), Color(0xFF6D1414))),
    ('okra', CropStyle('🌿', Color(0xFF81C784), Color(0xFF14471F))),
    ('bitter', CropStyle('🥒', Color(0xFF7CB342), Color(0xFF14471F))),
    ('cucumber', CropStyle('🥒', Color(0xFF81C784), Color(0xFF1B5E20))),
    ('watermelon', CropStyle('🍉', Color(0xFFEF9A9A), Color(0xFF1B5E20))),
    ('melon', CropStyle('🍈', Color(0xFFDCE775), Color(0xFF558B2F))),
    ('gourd', CropStyle('🥒', Color(0xFFAED581), Color(0xFF33691E))),
    ('brinjal', CropStyle('🍆', Color(0xFFBA68C8), Color(0xFF3F1D5C))),
    ('pea', CropStyle('🫛', Color(0xFF9CCC65), Color(0xFF2E6B1F))),
    ('carrot', CropStyle('🥕', Color(0xFFFFB347), Color(0xFFA8400C))),
    ('paddy', CropStyle('🌾', Color(0xFFFFD54F), Color(0xFF8A5A00))),
    ('rice', CropStyle('🌾', Color(0xFFFFD54F), Color(0xFF8A5A00))),
    ('onion', CropStyle('🧅', Color(0xFFF48FB1), Color(0xFF7B1F4B))),
    ('cabbage', CropStyle('🥬', Color(0xFFA5D6A7), Color(0xFF1F5A30))),
    ('cauliflower', CropStyle('🥦', Color(0xFFC5E1A5), Color(0xFF33691E))),
    ('spinach', CropStyle('🥬', Color(0xFF81C784), Color(0xFF124D22))),
    ('coriander', CropStyle('🌿', Color(0xFFA5D6A7), Color(0xFF1F5A30))),
  ];

  /// The style for a crop, by its name ("Tomato", "Bitter Gourd", ...).
  static CropStyle of(String crop) {
    final name = crop.toLowerCase();
    for (final (word, style) in _styles) {
      if (name.contains(word)) return style;
    }
    return _fallback;
  }
}
