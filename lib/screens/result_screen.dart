// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lottery_result.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_ad_widget.dart';
import 'history_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<int> selectedNumbers = [];
  Map<String, String>? lottery;
  LotteryResult? lotteryResult;
  String? selectedTeam; // Para Timemania
  bool isLoading = true;

  List<int> matchedNumbers = []; // Adicionado

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    selectedNumbers = List<int>.from(args['selectedNumbers']);
    lottery = Map<String, String>.from(args['lottery']);
    selectedTeam = args['selectedTeam'];

    _fetchLotteryResult();
  }

  void _fetchLotteryResult() async {
    String? apiName = lottery?['apiName'];

    if (apiName == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    LotteryResult? result = await ApiService().getCachedResult(apiName);

    result ??= await ApiService().fetchLatestResult(apiName);

    if (result != null) {
      List<int> drawnNumbers = result.listaDezenas;
      matchedNumbers = selectedNumbers
          .where((number) => drawnNumbers.contains(number))
          .toList();
    }

    setState(() {
      lotteryResult = result;
      isLoading = false;
    });
  }

  Future<void> _saveToHistory() async {
    if (lotteryResult != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('history') ?? [];

      // Crie uma entrada de resultado
      Map<String, dynamic> resultEntry = {
        'lotteryName': lottery!['name'],
        'selectedNumbers': selectedNumbers,
        'drawnNumbers': lotteryResult!.listaDezenas,
        'date': lotteryResult!.dataApuracao,
        'concurso': lotteryResult!.numero,
        'matchedNumbers': matchedNumbers,
        'numCorrect': matchedNumbers.length,
      };

      // Adicione dados específicos
      if (lottery!['apiName'] == 'timemania') {
        resultEntry['selectedTeam'] = selectedTeam;
        resultEntry['matchedTeam'] = selectedTeam != null &&
                lotteryResult!.rateioPremios.containsKey(selectedTeam!)
            ? selectedTeam
            : null;
      }

      // Salve o histórico como JSON
      history.add(json.encode(resultEntry));
      await prefs.setStringList('history', history);

      // Mostre uma confirmação
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado salvo no histórico!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Resultado',
          showBackButton: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (lotteryResult == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Resultado',
          showBackButton: false,
        ),
        body: const Center(
          child: Text(
            'Erro ao obter os resultados. Tente novamente.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    List<int> drawnNumbers = lotteryResult!.listaDezenas;

    return Scaffold(
      appBar: CustomAppBar(
        title:
            'Resultado do Concurso ${lotteryResult!.numero} - ${lottery!['name']}',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Detalhes do Concurso
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Data: ${lotteryResult!.dataApuracao}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seus Números:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    children: selectedNumbers.map((number) {
                      bool isMatched = matchedNumbers.contains(number);
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isMatched ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Text(
                            number.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Números Sorteados:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    children: drawnNumbers.map((number) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Text(
                            number.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Você acertou ${matchedNumbers.length} números!',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Rateio de Prêmios
                  if (lotteryResult!.rateioPremios.isNotEmpty) ...[
                    const Text(
                      'Rateio de Prêmios:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ...lotteryResult!.rateioPremios.entries.map((entry) {
                      return Text(
                        '${entry.key}: R\$ ${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    'Próximo concurso estimado em: R\$ ${lotteryResult!.valorAcumuladoProximoConcurso.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Botões
                  ElevatedButton(
                    onPressed: _saveToHistory,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      'Salvar no Histórico',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/manual_entry',
                          arguments: lottery);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Continuar Conferindo',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/history');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text(
                      'Ver Histórico',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
