import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// The app's colours for one brightness (light or dark).
///
/// Screens read these through `context.colors`, so they follow the theme:
/// switch to dark mode and every screen repaints with the dark set. Use the
/// fixed constants in [AppColors] only for things that must look the same in
/// both themes (the gold "Not available yet" stamp, the cart badge).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.green,
    required this.greenLight,
    required this.gold,
    required this.goldInk,
    required this.brand,
    required this.danger,
  });

  static const light = AppPalette(
    background: AppColors.background,
    card: AppColors.card,
    ink: AppColors.ink,
    muted: AppColors.muted,
    line: AppColors.line,
    green: AppColors.green,
    greenLight: AppColors.greenLight,
    gold: AppColors.gold,
    goldInk: AppColors.brown,
    brand: AppColors.green,
    danger: Color(0xFFC62828),
  );

  static const dark = AppPalette(
    background: AppColors.backgroundDark,
    card: AppColors.cardDark,
    ink: AppColors.inkDark,
    muted: AppColors.mutedDark,
    line: AppColors.lineDark,
    green: AppColors.greenDark,
    greenLight: Color(0xFF7CCB8D),
    gold: AppColors.goldDark,
    goldInk: AppColors.goldDark,
    brand: Color(0xFF2A6E3F),
    danger: Color(0xFFEF9A9A),
  );

  final Color background; // page background
  final Color card; // cards, sheets, bars
  final Color ink; // main text
  final Color muted; // secondary text
  final Color line; // borders / dividers

  /// Green as an accent on the background: icons, links, outlined buttons.
  final Color green;
  final Color greenLight;
  final Color gold;

  /// Text and icons on a gold-tinted notice.
  final Color goldInk;

  /// Solid green that sits behind white text: app bars, main buttons.
  final Color brand;

  /// Errors and destructive actions.
  final Color danger;

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? ink,
    Color? muted,
    Color? line,
    Color? green,
    Color? greenLight,
    Color? gold,
    Color? goldInk,
    Color? brand,
    Color? danger,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      green: green ?? this.green,
      greenLight: greenLight ?? this.greenLight,
      gold: gold ?? this.gold,
      goldInk: goldInk ?? this.goldInk,
      brand: brand ?? this.brand,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      card: mix(card, other.card),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      green: mix(green, other.green),
      greenLight: mix(greenLight, other.greenLight),
      gold: mix(gold, other.gold),
      goldInk: mix(goldInk, other.goldInk),
      brand: mix(brand, other.brand),
      danger: mix(danger, other.danger),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The colours for the current theme. Falls back to the light set where no
  /// app theme is installed (the admin panel, simple widget tests).
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
