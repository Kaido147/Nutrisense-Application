import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/firebase_options.dart';
import 'package:provider/provider.dart' as p;
import 'package:nutrisense/theme_provider.dart';
import 'package:nutrisense/login.dart';
import 'package:nutrisense/providers/firebase_providers.dart';

import 'landing_page.dart';
import 'layout/main_navigation.dart';
import 'pages/register.dart';
import 'setgoals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    p.ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return p.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final accentColor = themeProvider.accentColor.color;

        final lightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.light(
            primary: accentColor,
            secondary: accentColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF243A6E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          scaffoldBackgroundColor: Colors.white,
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: accentColor,
            secondary: accentColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF243A6E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nutrisense',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.flutterThemeMode,
          home: const AuthGate(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/setgoals': (context) => const SetGoalsPage(),
            '/main': (context) => const MainNavigation(),
          },
        );
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<User?> authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) =>
          user == null ? const LandingPage() : const MainNavigation(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LandingPage(),
    );
  }
}
