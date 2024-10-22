// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../utils/ad_manager.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> lotteries = [
    {'name': 'Lotofácil', 'apiName': 'lotofacil'},
    {'name': 'Mega-Sena', 'apiName': 'megasena'},
    {'name': 'Quina', 'apiName': 'quina'},
    {'name': 'Lotomania', 'apiName': 'lotomania'},
    {'name': 'Dupla Sena', 'apiName': 'duplasena'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Loterias - Resultado Fácil',
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Botão de ação
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Ver Histórico'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () async {
                await AdManager.showInterstitialAd(() async {
                  Navigator.pushNamed(context, '/history');
                });
              },
            ),
          ),
          // Lista de loterias
          Expanded(
            child: ListView.builder(
              itemCount: lotteries.length,
              itemBuilder: (context, index) {
                final lottery = lotteries[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        lottery['name']![0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      lottery['name']!,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await AdManager.showInterstitialAd(() async {
                        Navigator.pushNamed(
                          context,
                          '/multiple_entry',
                          arguments: lottery,
                        );
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
