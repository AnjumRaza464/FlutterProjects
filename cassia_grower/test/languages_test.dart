// Tests that selecting any of the six languages translates the whole app and
// lays the four Perso-Arabic languages out right to left. These do not build
// Home (which needs Firebase), so they can run in the test harness and prove
// the language-switching mechanism directly.

import 'package:cassia_grower/l10n/app_strings.dart';
import 'package:cassia_grower/main.dart';
import 'package:cassia_grower/state/app_settings.dart';
import 'package:cassia_grower/state/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A tiny screen that shows a word that is different in every language, so a
/// test can read which language the app is in.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(context.s.send)));
}

/// The [AppStrings] for a language, from its public constant.
AppStrings _strings(AppLanguage language) => switch (language) {
      AppLanguage.en => AppStrings.en,
      AppLanguage.ur => AppStrings.ur,
      AppLanguage.sd => AppStrings.sd,
      AppLanguage.pa => AppStrings.pa,
      AppLanguage.ps => AppStrings.ps,
      AppLanguage.bal => AppStrings.bal,
    };

/// The word "Send" in each language — all six are distinct.
const _send = {
  AppLanguage.en: 'Send',
  AppLanguage.ur: 'بھیجیں',
  AppLanguage.sd: 'موڪليو',
  AppLanguage.pa: 'بھیجو',
  AppLanguage.ps: 'ولیږئ',
  AppLanguage.bal: 'رئوان کن اِت',
};

void main() {
  group('AppStrings for every language', () {
    test('each language returns its own wording, never a fallback', () {
      for (final entry in _send.entries) {
        final s = _strings(entry.key);
        expect(s.send, entry.value,
            reason: 'send in ${entry.key.code} should be its own translation');
        expect(s.languageCode, entry.key.code);
      }
    });

    test('English reads left to right, the rest right to left', () {
      for (final language in AppLanguage.values) {
        final rtl = language != AppLanguage.en;
        expect(_strings(language).isRtl, rtl,
            reason: '${language.code} isRtl should be $rtl');
        expect(language.rtl, rtl);
      }
    });
  });

  group('Switching the live app', () {
    for (final language in AppLanguage.values) {
      testWidgets('choosing ${language.label} shows it and lays it out '
          '${language.rtl ? 'right to left' : 'left to right'}',
          (tester) async {
        final settings = AppSettings()..setLanguage(language);
        await tester.pumpWidget(CassiaApp(
          settings: settings,
          cart: CartController(),
          home: const _Probe(),
        ));
        await tester.pumpAndSettle();

        // The whole app is in the chosen language…
        expect(find.text(_send[language]!), findsOneWidget);
        // …and laid out the way that language reads.
        expect(
          Directionality.of(tester.element(find.byType(_Probe))),
          language.rtl ? TextDirection.rtl : TextDirection.ltr,
        );
      });
    }

    testWidgets('changing the setting re-translates the running app',
        (tester) async {
      final settings = AppSettings();
      await tester.pumpWidget(CassiaApp(
        settings: settings,
        cart: CartController(),
        home: const _Probe(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Send'), findsOneWidget);

      for (final language in [
        AppLanguage.sd,
        AppLanguage.ps,
        AppLanguage.bal,
        AppLanguage.pa,
      ]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        expect(find.text(_send[language]!), findsOneWidget);
        expect(find.text('Send'), findsNothing);
      }
    });
  });
}
