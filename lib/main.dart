import 'package:flutter/material.dart';
import 'layout/main_navigation.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // ← ADDED
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
      theme: ThemeData(
        useMaterial3: true,
        // ← REMOVED duplicate AppBarTheme SystemUiOverlayStyle (was conflicting)
      ),
      debugShowCheckedModeBanner: false,
      title: "Nutrisense",
      home: const MainNavigation(), // ← ADDED const
    );
  }
}