import 'package:flutter/material.dart';
import 'package:nutrisense/login.dart';
import 'landing_page.dart';
import 'layout/main_navigation.dart';
import 'pages/register.dart';
import 'setgoals.dart';
import 'package:flutter/services.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Nutrisense",
      theme: ThemeData(useMaterial3: true),

      home: const LandingPage(),


      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/setgoals': (context) => const SetGoalsPage(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}