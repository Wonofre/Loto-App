// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lottery_result.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_ad_widget.dart';
import 'history_screen.dart';
import 'package:intl/intl.dart'; // Importação para formatação monetária
import 'manual_entry_screen.dart';
import '../utils/ad_manager.dart';

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
  int? contestNumber; // Adicionado

  List<int> matchedNumbers = []; // Adicionado

  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'pt_BR'); // Formato monetário

  @override
  void initState() {
    super.initState();
    // Atrasar a obtenção dos argumentos para garantir que o contexto esteja disponível
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      setState(() {
        selectedNumbers = List<int>.from(args['selectedNumbers']);
        lottery = Map<String, String>.from(args['lottery']);
        selectedTeam = args['selectedTeam'];
        contestNumber = args['contestNumber'];
      });
      _fetchLotteryResult();
    });
  }

  void _fetchLotteryResult() async {
    String? apiName = lottery?['apiName'];

    if (apiName == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    LotteryResult? result;

    if (contestNumber != null) {
      // Busca o resultado pelo número do concurso
      result = await ApiService()
          .fetchResultByContestNumber(apiName, contestNumber!);
    } else {
      // Busca o último resultado
      result = await ApiService().fetchLatestResult(apiName);
    }

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

    if (result == null && contestNumber != null) {
      // Exibir uma mensagem clara se o concurso não for encontrado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível encontrar o concurso $contestNumber para ${lottery!['name']}.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showContestNumberDialog() {
    final _contestNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Digite o número do concurso'),
          content: TextField(
            controller: _contestNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Número do Concurso',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final contestNumberInput =
                    int.tryParse(_contestNumberController.text);
                if (contestNumberInput != null) {
                  Navigator.pop(context);
                  setState(() {
                    isLoading = true;
                    contestNumber = contestNumberInput;
                  });
                  _fetchLotteryResult();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, insira um número válido.')),
                  );
                }
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isLoading
          ? const CustomAppBar(
              title: 'Resultado',
              showBackButton: false,
            )
          : CustomAppBar(
              title:
                  'Resultado do Concurso ${lotteryResult?.numero ?? contestNumber ?? ''} - ${lottery!['name']}',
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showContestNumberDialog,
                ),
              ],
            ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : lotteryResult == null
              ? Center(
                  child: Text(
                    contestNumber != null
                        ? 'Não foi possível encontrar o concurso $contestNumber para ${lottery!['name']}.'
                        : 'Erro ao obter os resultados. Tente novamente.',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
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
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              children: selectedNumbers.map((number) {
                                bool isMatched =
                                    matchedNumbers.contains(number);
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        isMatched ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      number.toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Números Sorteados:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              children:
                                  lotteryResult!.listaDezenas.map((number) {
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      number.toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
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
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              ...lotteryResult!.rateioPremios.entries
                                  .map((entry) {
                                return Text(
                                  '${entry.key}: ${formatCurrency.format(entry.value)}',
                                  style: const TextStyle(fontSize: 16),
                                );
                              }).toList(),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              'Próximo concurso estimado em: ${formatCurrency.format(lotteryResult!.valorAcumuladoProximoConcurso)}',
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
                            // Wrap Navigator.push with AdManager.showInterstitialAd
                            ElevatedButton(
                              onPressed: () {
                                AdManager.showInterstitialAd(() async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManualEntryScreen(
                                              showSaveButton: false),
                                      settings: RouteSettings(arguments: {
                                        'lottery': lottery,
                                      }),
                                    ),
                                  );
                                });
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
