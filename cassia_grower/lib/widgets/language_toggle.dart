import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../state/app_settings.dart';

/// A button that switches the whole app between English and Urdu.
///
/// It shows the language it switches TO ("اردو" while the app is in English),
/// so it reads as an invitation rather than a status. The AI features answer
/// in whichever language the app is in.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.color = Colors.white});

  /// Text and icon colour; white suits the green app bars.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    // No settings installed (a bare widget test): nothing to switch.
    if (settings == null) return const SizedBox.shrink();

    return Tooltip(
      message: context.s.changeLanguage,
      child: TextButton.icon(
        onPressed: settings.toggleLanguage,
        icon: const Icon(Icons.language, size: 18),
        label: Text(
          context.s.otherLanguage,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}
