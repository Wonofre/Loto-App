// lib/screens/result_multiple_screen.dart
import 'package:flutter/material.dart';
import '../models/lottery_game.dart';
import '../models/lottery_result.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_ad_widget.dart';
import 'history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Importação para formatação monetária

class ResultMultipleScreen extends StatefulWidget {
  const ResultMultipleScreen({super.key});

  @override
  _ResultMultipleScreenState createState() => _ResultMultipleScreenState();
}

class _ResultMultipleScreenState extends State<ResultMultipleScreen> {
  List<LotteryGame> games = [];
  Map<String, LotteryResult?> results = {};
  Map<String, String> errorMessages =
      {}; // Para armazenar mensagens de erro por jogo
  bool isLoading = true;
  int? contestNumber; // Para permitir inserção de número do concurso

  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'pt_BR'); // Formato monetário

  @override
  void initState() {
    super.initState();
    // Atrasar a obtenção dos argumentos para garantir que o contexto esteja disponível
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      setState(() {
        games = List<LotteryGame>.from(args['games']);
        contestNumber = args['contestNumber'];
      });
      _fetchAllResults();
    });
  }

  void _fetchAllResults() async {
    setState(() {
      isLoading = true;
      results = {};
      errorMessages = {};
    });

    for (var game in games) {
      String apiName = game.lottery['apiName']!;
      LotteryResult? result;

      try {
        if (contestNumber != null) {
          // Busca o resultado pelo número do concurso, se fornecido
          result = await ApiService()
              .fetchResultByContestNumber(apiName, contestNumber!);
          if (result == null) {
            // Concurso não encontrado
            errorMessages[apiName] =
                'Não foi possível encontrar o concurso $contestNumber para ${game.lottery['name']}.';
          }
        } else {
          // Busca o último resultado
          result = await ApiService().fetchLatestResult(apiName);
          if (result == null) {
            errorMessages[apiName] =
                'Erro ao obter o último resultado para ${game.lottery['name']}.';
          }
        }
      } catch (e) {
        // Erro ao buscar o resultado
        errorMessages[apiName] =
            'Erro ao buscar resultados para ${game.lottery['name']}.';
        print('Erro ao buscar resultado para $apiName: $e');
      }

      results[apiName] = result;
    }

    setState(() {
      isLoading = false;
    });

    // Exibir mensagens de erro específicas após a busca
    if (errorMessages.isNotEmpty) {
      errorMessages.forEach((apiName, message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  Future<void> _saveAllToHistory() async {
    if (results.isEmpty) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history') ?? [];

    for (var game in games) {
      String apiName = game.lottery['apiName']!;
      LotteryResult? result = results[apiName]!;

      if (result == null) continue;

      List<int> drawnNumbers = result.listaDezenas;
      List<int> matchedNumbers = game.selectedNumbers
          .where((number) => drawnNumbers.contains(number))
          .toList();

      // Crie uma entrada de resultado
      Map<String, dynamic> resultEntry = {
        'lotteryName': game.lottery['name'],
        'selectedNumbers': game.selectedNumbers,
        'drawnNumbers': result.listaDezenas,
        'date': result.dataApuracao,
        'concurso': result.numero,
        'matchedNumbers': matchedNumbers,
        'numCorrect': matchedNumbers.length,
      };

      // Adicione dados específicos
      if (game.lottery['apiName'] == 'timemania') {
        resultEntry['selectedTeam'] = game.selectedTeam;
        resultEntry['matchedTeam'] = game.selectedTeam != null &&
                result.rateioPremios.containsKey(game.selectedTeam!)
            ? game.selectedTeam
            : null;
      }

      // Salve o histórico como JSON
      history.add(json.encode(resultEntry));
    }

    await prefs.setStringList('history', history);

    // Mostre uma confirmação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resultados salvos no histórico!')),
    );
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
                    contestNumber = contestNumberInput;
                  });
                  _fetchAllResults();
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

  Widget _buildGameCard(LotteryGame game, LotteryResult? result) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'pt_BR'); // Formato monetário

    if (result == null) {
      // Exibir mensagem específica de erro se disponível
      String? errorMessage = errorMessages[game.lottery['apiName']!];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(
            '${game.lottery['name']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            errorMessage ?? 'Erro ao obter resultados.',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    List<int> drawnNumbers = result.listaDezenas;
    List<int> matchedNumbers = game.selectedNumbers
        .where((number) => drawnNumbers.contains(number))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${game.lottery['name']} - Concurso ${result.numero}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Data: ${result.dataApuracao}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seus Números:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              children: game.selectedNumbers.map((number) {
                bool isMatched = matchedNumbers.contains(number);
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isMatched ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (game.selectedTeam != null) ...[
              const SizedBox(height: 8),
              Text(
                'Seu Time: ${game.selectedTeam}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Números Sorteados:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              children: drawnNumbers.map((number) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Você acertou ${matchedNumbers.length} números!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Rateio de Prêmios
            if (result.rateioPremios.isNotEmpty) ...[
              const Text(
                'Rateio de Prêmios:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ...result.rateioPremios.entries.map((entry) {
                return Text(
                  '${entry.key}: ${formatCurrency.format(entry.value)}',
                  style: const TextStyle(fontSize: 14),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Resultados Múltiplos',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed:
                _showContestNumberDialog, // Botão para inserir número de concurso
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final result = results[game.lottery['apiName']!];
                      return _buildGameCard(game, result);
                    },
                  ),
                  // Botão para salvar todos os resultados no histórico
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _saveAllToHistory,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        'Salvar Todos os Resultados no Histórico',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              ),
            ),
    );
  }
}
