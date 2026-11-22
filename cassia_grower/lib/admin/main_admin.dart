import 'package:material_ui/material_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_options.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

/// Entry point for the Cassia Seed ADMIN web panel.
///
/// This is a separate target from the farmer app (lib/main.dart). It reuses
/// the same Firebase project, Product model and theme. Run / build it with:
///
///   flutter run   -d chrome        -t lib/admin/main_admin.dart
///   flutter build web              -t lib/admin/main_admin.dart
///
/// See lib/admin/ADMIN.md for the one-time web + Firebase setup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cassia Seed – Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          primary: AppColors.green,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen when signed out, the dashboard when signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null
            ? const LoginScreen()
            : const DashboardScreen();
      },
    );
  }
}
