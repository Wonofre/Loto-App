import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import the package
import 'screens/home_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Mobile Ads SDK
  final InitializationStatus initializationStatus =
      await MobileAds.instance.initialize();

  runApp(LoteriasApp());
}

class LoteriasApp extends StatelessWidget {
  const LoteriasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loterias - Resultado Fácil',
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/manual_entry': (context) => ManualEntryScreen(),
        '/result': (context) => ResultScreen(),
        '/history': (context) => HistoryScreen(),
      },
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 17, 89, 197), // Cor primária (roxo)
        hintColor: Color.fromARGB(255, 255, 255, 255), // Cor de destaque
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Color.fromARGB(255, 3, 104, 235),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(221, 255, 166, 0), // Cor dos botões
          ),
        ),
      ),
    );
  }
}
