import 'package:material_ui/material_ui.dart';

import '../data/local_store.dart';

/// The languages the app is written in.
///
/// English is left-to-right; every other language here is written in a
/// Perso-Arabic script and reads right-to-left. Each is named in its own
/// script so it can always be recognised, whatever language the app is in.
enum AppLanguage {
  en('en', 'English', 'EN', rtl: false),
  ur('ur', 'اردو', 'اردو'),
  sd('sd', 'سنڌي', 'سنڌي'),
  pa('pa', 'پنجابی', 'پنجابی'),
  ps('ps', 'پښتو', 'پښتو'),
  bal('bal', 'بلوچی', 'بلوچی');

  const AppLanguage(this.code, this.label, this.shortLabel, {this.rtl = true});

  /// The language code, as used for the locale and sent to the AI features.
  final String code;

  /// The language's own name, shown in the language menus.
  final String label;

  /// A short form of [label] for the compact header button.
  final String shortLabel;

  /// Whether the language reads right-to-left (every one here but English).
  final bool rtl;

  /// The locale handed to Flutter's own Material widgets (date pickers, the
  /// copy/paste menu). Flutter ships translations for English and Urdu only,
  /// so the four regional languages reuse Urdu's right-to-left layout — their
  /// own words come from [AppStrings], not from Flutter.
  Locale get materialLocale => rtl ? const Locale('ur') : const Locale('en');
}

/// The farmer's choices for the whole app: language and light/dark theme.
/// Both are remembered on the phone.
class AppSettings extends ChangeNotifier {
  /// [deviceLocale] decides the language the first time the app is opened:
  /// a phone set to one of the app's languages starts in that language, any
  /// other starts in English.
  AppSettings({LocalStore? store, Locale? deviceLocale})
      : _store = store ?? MemoryStore() {
    final savedLanguage = _store.read(_languageKey);
    _language = AppLanguage.values.firstWhere(
      (l) => l.code == savedLanguage,
      orElse: () => AppLanguage.values.firstWhere(
        (l) => l.code == deviceLocale?.languageCode,
        orElse: () => AppLanguage.en,
      ),
    );
    final savedTheme = _store.read(_themeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
  }

  static const _languageKey = 'settings.language';
  static const _themeKey = 'settings.theme';

  final LocalStore _store;
  late AppLanguage _language;
  late ThemeMode _themeMode;

  AppLanguage get language => _language;

  /// [ThemeMode.system] follows the phone's own light/dark setting.
  ThemeMode get themeMode => _themeMode;

  void setLanguage(AppLanguage language) {
    if (language == _language) return;
    _language = language;
    _store.write(_languageKey, language.code);
    notifyListeners();
  }

  /// Switches between English and Urdu.
  void toggleLanguage() {
    setLanguage(_language == AppLanguage.en ? AppLanguage.ur : AppLanguage.en);
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    _store.write(_themeKey, mode.name);
    notifyListeners();
  }
}

/// Makes the one [AppSettings] available to every screen.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  /// The settings, or null where none are installed (simple widget tests).
  /// The calling widget rebuilds whenever a setting changes.
  static AppSettings? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
  }

  static AppSettings of(BuildContext context) => maybeOf(context)!;
}
