import 'package:material_ui/material_ui.dart';

import '../data/local_store.dart';

/// The languages the app is written in.
enum AppLanguage {
  en('en'),
  ur('ur');

  const AppLanguage(this.code);

  /// The language code, as used for the locale and sent to the AI features.
  final String code;

  Locale get locale => Locale(code);
}

/// The farmer's choices for the whole app: language and light/dark theme.
/// Both are remembered on the phone.
class AppSettings extends ChangeNotifier {
  /// [deviceLocale] decides the language the first time the app is opened:
  /// a phone set to Urdu starts in Urdu, any other starts in English.
  AppSettings({LocalStore? store, Locale? deviceLocale})
      : _store = store ?? MemoryStore() {
    final savedLanguage = _store.read(_languageKey);
    _language = AppLanguage.values.firstWhere(
      (l) => l.code == savedLanguage,
      orElse: () =>
          deviceLocale?.languageCode == 'ur' ? AppLanguage.ur : AppLanguage.en,
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
