import 'package:flutter/material.dart';
import 'screens/inicio_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrujulaUnisonApp());
}

class BrujulaUnisonApp extends StatelessWidget {
  const BrujulaUnisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brujula Unison',

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.blue,
      ),

      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}