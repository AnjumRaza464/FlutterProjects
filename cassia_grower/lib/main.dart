import 'package:material_ui/material_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local_store.dart';
import 'data/product_repository.dart';
import 'firebase_options.dart';
import 'state/app_settings.dart';
import 'state/cart_controller.dart';
import 'state/cart_scope.dart';
import 'state/favourites.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Flutter must be ready before we call native code like Firebase.
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Connect the app to the Firebase project (cassia-seed).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Things remembered on the phone: language, theme, and the cart.
  final store = PrefsStore(await SharedPreferences.getInstance());

  final settings = AppSettings(
    store: store,
    deviceLocale: binding.platformDispatcher.locale,
  );

  // The cart follows the live catalog, so a variety that stops being
  // available leaves the cart straight away.
  final cart = CartController(store: store)
    ..watchCatalog(ProductRepository().watchProducts());

  runApp(CassiaApp(
    settings: settings,
    cart: cart,
    favourites: FavouritesController(store: store),
  ));
}

class CassiaApp extends StatelessWidget {
  CassiaApp({
    super.key,
    required this.settings,
    required this.cart,
    FavouritesController? favourites,
    this.home = const SplashGate(),
  }) : favourites = favourites ?? FavouritesController();

  final AppSettings settings;
  final CartController cart;

  /// The farmer's saved varieties. Left out (as in tests), they are kept
  /// only while the app runs.
  final FavouritesController favourites;

  /// The first screen; replaceable in tests.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    // The scopes sit above MaterialApp, so every page — tabs, pushed screens
    // and sheets — shares the same settings, cart and favourites.
    return AppSettingsScope(
      settings: settings,
      child: CartScope(
        cart: cart,
        child: FavouritesScope(
          favourites: favourites,
          // Rebuilds the app when the language or theme setting changes.
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              final urdu = settings.language == AppLanguage.ur;
              return MaterialApp(
                title: 'Cassia Grower',
                debugShowCheckedModeBanner: false,
                // Urdu switches the whole app to right-to-left.
                locale: settings.language.locale,
                supportedLocales: [
                  for (final language in AppLanguage.values) language.locale,
                ],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                theme: buildAppTheme(Brightness.light, cursive: urdu),
                darkTheme: buildAppTheme(Brightness.dark, cursive: urdu),
                themeMode: settings.themeMode,
                home: home,
              );
            },
          ),
        ),
      ),
    );
  }
}
