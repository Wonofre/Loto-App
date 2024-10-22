// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/multiple_entry_screen.dart';
import 'screens/result_screen.dart';
import 'screens/result_multiple_screen.dart';
// Remova a importação de 'scan_ticket_screen.dart' se não for necessária
import 'utils/ad_manager.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
  AdManager.initialize();
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
        fontFamily: GoogleFonts.roboto().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textTheme: TextTheme(
          displayLarge:
              GoogleFonts.roboto(fontSize: 72.0, fontWeight: FontWeight.bold),
          titleLarge:
              GoogleFonts.roboto(fontSize: 20.0, fontWeight: FontWeight.bold),
          bodyMedium: GoogleFonts.roboto(fontSize: 16.0),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      initialRoute: '/home_screen',
      routes: {
        '/home_screen': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/manual_entry': (context) =>
            const ManualEntryScreen(showSaveButton: false),
        '/multiple_entry': (context) => const MultipleEntryScreen(),
        '/result': (context) => const ResultScreen(),
        '/result_multiple': (context) => const ResultMultipleScreen(),
      },
    );
  }
}
