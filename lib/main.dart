import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nutrisense/theme_provider.dart';
import 'package:nutrisense/login.dart';
import 'landing_page.dart';
import 'layout/main_navigation.dart';
import 'pages/register.dart';
import 'setgoals.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Define accent color as primary in colorScheme
          final accentColor = themeProvider.accentColor.color;

          // Light theme
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

          // Dark theme
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
            title: "Nutrisense",
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.flutterThemeMode,
            home: const LandingPage(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/setgoals': (context) => const SetGoalsPage(),
              '/main': (context) => const MainNavigation(),
            },
          );
        },
      ),
    );
  }
}