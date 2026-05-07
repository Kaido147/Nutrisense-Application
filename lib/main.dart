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

import 'health_profile_setup.dart';
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
        final primaryColor = themeProvider.primaryColorValue;

        final lightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            secondary: accentColor,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: primaryColor,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          scaffoldBackgroundColor: Colors.white,
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: primaryColor,
            secondary: accentColor,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: primaryColor,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor,
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
            '/health-profile': (context) => const HealthProfileSetupPage(),
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
      data: (user) {
        if (user == null) {
          return const LandingPage();
        }

        final profileAsync = ref.watch(currentUserProfileProvider);
        final healthProfileAsync = ref.watch(healthProfileProvider);

        return profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const LandingPage();
            }
            if (!profile.onboardingCompleted) {
              return const SetGoalsPage();
            }

            return healthProfileAsync.when(
              data: (healthProfile) {
                if (healthProfile == null || !healthProfile.isComplete) {
                  return const HealthProfileSetupPage();
                }
                return const MainNavigation();
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const HealthProfileSetupPage(),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const LandingPage(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LandingPage(),
    );
  }
}
