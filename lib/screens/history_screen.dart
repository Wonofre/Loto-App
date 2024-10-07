import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // Load saved history from SharedPreferences
  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('history');

    if (history != null) {
      setState(() {
        // Cast each result from dynamic to Map<String, dynamic>
        savedResults = history
            .map((result) => json.decode(result) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Conferências'),
      ),
      body: savedResults.isNotEmpty
          ? ListView.builder(
              itemCount: savedResults.length,
              itemBuilder: (context, index) {
                final result = savedResults[index];
                return ListTile(
                  title: Text(
                    '${result['lotteryName']} - Concurso: ${result['concurso']} - Data: ${result['date']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Acertos: ${result['numCorrect']} - Números sorteados: ${result['drawnNumbers']}',
                  ),
                );
              },
            )
          : Center(
              child: Text('Nenhum resultado salvo no histórico.'),
            ),
    );
  }
}
