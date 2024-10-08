// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_ad_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> savedResults = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Carrega o histórico salvo no SharedPreferences
  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('history');

    if (history != null) {
      setState(() {
        savedResults = history
            .map((result) => json.decode(result) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Histórico de Conferências',
      ),
      body: Column(
        children: [
          Expanded(
            child: savedResults.isNotEmpty
                ? ListView.builder(
                    itemCount: savedResults.length,
                    itemBuilder: (context, index) {
                      final result = savedResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              result['lotteryName'][0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${result['lotteryName']} - Concurso: ${result['concurso']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Data: ${result['date']}'),
                              Text('Acertos: ${result['numCorrect']}'),
                              Text(
                                  'Números Sorteados: ${result['drawnNumbers'].join(', ')}'),
                              if (result.containsKey('selectedTeam') &&
                                  result['selectedTeam'] != null) ...[
                                Text(
                                    'Time Selecionado: ${result['selectedTeam']}'),
                                if (result['matchedTeam'] != null)
                                  Text(
                                      'Time Acertado: ${result['matchedTeam']}'),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Nenhum resultado salvo no histórico.',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
