// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:intl/intl.dart'; // Importação para formatação de datas

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

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('history');

    if (history != null) {
      try {
        setState(() {
          savedResults = history
              .map((result) => json.decode(result) as Map<String, dynamic>)
              .toList();
        });
      } catch (e) {
        prefs.remove('history');
        setState(() {
          savedResults = [];
        });
        print('Erro ao carregar o histórico: $e');
      }
    }
  }

  Future<void> _deleteEntry(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedResults.removeAt(index);
      prefs.setStringList(
        'history',
        savedResults.map((e) => json.encode(e)).toList(),
      );
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
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
                      return Dismissible(
                        key: Key('$index-${result['concurso']}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteEntry(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Resultado removido do histórico.'),
                            ),
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                result['lotteryName'] != null
                                    ? result['lotteryName'][0]
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              '${result['lotteryName'] ?? 'Loteria Desconhecida'} - Concurso: ${result['concurso'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Data do Jogo: ${_formatDate(result['savedDate'])}'),
                                Text(
                                    'Data do Sorteio: ${_formatDate(result['date'])}'),
                                Text('Acertos: ${result['numCorrect'] ?? 0}'),
                                Text(
                                    'Números Sorteados: ${result['drawnNumbers'] != null ? result['drawnNumbers'].join(', ') : 'N/A'}'),
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
