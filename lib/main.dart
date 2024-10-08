// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/multiple_entry_screen.dart';
import 'screens/result_screen.dart';
import 'screens/result_multiple_screen.dart';
import 'utils/ad_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  AdManager.loadInterstitialAd(); // Inicializa o anúncio intersticial
  runApp(const LotteryApp());
}

class LotteryApp extends StatelessWidget {
  const LotteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loterias - Resultado Fácil',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Cor de fundo
            foregroundColor: Colors.white, // Cor do texto
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/manual_entry': (context) => const ManualEntryScreen(),
        '/multiple_entry': (context) => const MultipleEntryScreen(),
        '/result': (context) => const ResultScreen(),
        '/result_multiple': (context) => const ResultMultipleScreen(),
      },
    );
  }
}
