import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../state/app_settings.dart';

/// A compact button that opens a menu of every language the app offers and
/// switches the whole app to the one chosen.
///
/// It shows the language the app is in now ("🌐 EN"), so it reads as the
/// current language. The AI features answer in whichever language is chosen.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.color = Colors.white});

  /// Text and icon colour; white suits the green app bars.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    // No settings installed (a bare widget test): nothing to switch.
    if (settings == null) return const SizedBox.shrink();

    return PopupMenuButton<AppLanguage>(
      tooltip: context.s.changeLanguage,
      position: PopupMenuPosition.under,
      onSelected: settings.setLanguage,
      itemBuilder: (context) => [
        for (final language in AppLanguage.values)
          PopupMenuItem(
            value: language,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (language == settings.language)
                  const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              settings.language.shortLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
