import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lottery_result.dart';
import '../services/api_service.dart';
import 'history_screen.dart'; // Import the History Screen

class ResultScreen extends StatefulWidget {
  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<int> selectedNumbers = [];
  Map<String, String>? lottery;
  LotteryResult? lotteryResult;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    selectedNumbers = args['selectedNumbers'];
    lottery = args['lottery'];

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

    LotteryResult? result = await ApiService.getCachedResult(apiName);

    if (result == null) {
      result = await ApiService.fetchLatestResult(apiName);
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

      // Create a result entry
      Map<String, dynamic> resultEntry = {
        'lotteryName': lottery!['name'],
        'selectedNumbers': selectedNumbers,
        'drawnNumbers': lotteryResult!.listaDezenas,
        'date': lotteryResult!.dataApuracao,
        'concurso': lotteryResult!.numero,
        'matchedNumbers': selectedNumbers
            .where((number) => lotteryResult!.listaDezenas.contains(number.toString()))
            .toList(),
        'numCorrect': selectedNumbers
            .where((number) => lotteryResult!.listaDezenas.contains(number.toString()))
            .length,
      };

      // Save history as JSON
      history.add(json.encode(resultEntry));
      await prefs.setStringList('history', history);

      // Show a confirmation that the result has been saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resultado salvo no histórico!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Resultado'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (lotteryResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Resultado'),
        ),
        body: Center(
          child: Text('Erro ao obter os resultados. Tente novamente.'),
        ),
      );
    }

    List<int> drawnNumbers = lotteryResult!.listaDezenas.map(int.parse).toList();
    List<int> matchedNumbers = selectedNumbers
        .where((number) => drawnNumbers.contains(number))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Resultado do Concurso ${lotteryResult!.numero} - ${lottery!['name']}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Data: ${lotteryResult!.dataApuracao}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Seus Números:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              children: selectedNumbers.map((number) {
                bool isMatched = matchedNumbers.contains(number);
                return Container(
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isMatched ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              'Números Sorteados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              children: drawnNumbers.map((number) {
                return Container(
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              'Você acertou ${matchedNumbers.length} números!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              
            ),
            Text(
                'Próximo concurso estimado em: R\$ ${lotteryResult!.valorAcumuladoProximoConcurso.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16),
             ),
            SizedBox(height: 20),

            // Save to History Button
            ElevatedButton(
              onPressed: _saveToHistory,
              child: Text('Salvar no Histórico'),
            ),

            // Continue Checking Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/manual_entry', arguments: lottery);
              },
              child: Text('Continuar Conferindo'),
            ),

            // View History Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
              child: Text('Ver Histórico'),
            ),
          ],
        ),
      ),
    );
  }
}
