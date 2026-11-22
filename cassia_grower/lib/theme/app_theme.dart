import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_palette.dart';

/// The farmer app's theme for [brightness].
///
/// App bars, buttons and text fields get their brand look here, once, so
/// individual screens don't repeat it and both themes stay consistent.
///
/// [cursive] is true for Urdu. Material's text styles put a little space
/// between letters, which breaks the joins of a connected script, so for
/// Urdu that spacing is removed from every style.
ThemeData buildAppTheme(Brightness brightness, {bool cursive = false}) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const label = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);

  final theme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
      primary: p.green,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: p.brand,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.brand,
        foregroundColor: Colors.white,
        shape: shape,
        textStyle: label,
        elevation: 3,
        shadowColor: const Color(0x662F7A3F),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.green,
        side: BorderSide(color: p.green),
        shape: shape,
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.green),
    ),
    dividerTheme: DividerThemeData(color: p.line),
    extensions: [p],
  );
  if (!cursive) return theme;
  return theme.copyWith(
    textTheme: _joined(theme.textTheme),
    primaryTextTheme: _joined(theme.primaryTextTheme),
  );
}

/// [theme] with the space between letters taken out of every style.
TextTheme _joined(TextTheme theme) {
  TextStyle? fix(TextStyle? style) => style?.copyWith(letterSpacing: 0);
  return theme.copyWith(
    displayLarge: fix(theme.displayLarge),
    displayMedium: fix(theme.displayMedium),
    displaySmall: fix(theme.displaySmall),
    headlineLarge: fix(theme.headlineLarge),
    headlineMedium: fix(theme.headlineMedium),
    headlineSmall: fix(theme.headlineSmall),
    titleLarge: fix(theme.titleLarge),
    titleMedium: fix(theme.titleMedium),
    titleSmall: fix(theme.titleSmall),
    bodyLarge: fix(theme.bodyLarge),
    bodyMedium: fix(theme.bodyMedium),
    bodySmall: fix(theme.bodySmall),
    labelLarge: fix(theme.labelLarge),
    labelMedium: fix(theme.labelMedium),
    labelSmall: fix(theme.labelSmall),
  );
}
