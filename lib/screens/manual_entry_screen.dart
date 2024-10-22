// lib/screens/manual_entry_screen.dart
import 'package:flutter/material.dart';
import '../models/lottery_game.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_ad_widget.dart';
import 'scan_ticket_screen.dart';
import 'package:intl/intl.dart'; // Importação para formatação monetária
import '../utils/ad_manager.dart';

class ManualEntryScreen extends StatefulWidget {
  final bool showSaveButton;

  const ManualEntryScreen({Key? key, required this.showSaveButton})
      : super(key: key);

  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  late Map<String, String> lottery;
  List<int> selectedNumbers = [];
  String? selectedTeam;
  bool isEditMode = false;
  LotteryGame? gameToEdit;
  int? contestNumber; // Adicionado para armazenar o número do concurso

  final _formKey = GlobalKey<FormState>();

  final List<String> teams = [
    'Flamengo', 'Palmeiras', 'São Paulo', 'Corinthians', 'Vasco',
    'Grêmio', 'Internacional', 'Botafogo', 'Santos', 'Atlético Mineiro',
    // Add more teams as needed
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;

    if (args is Map<String, dynamic>) {
      if (args.containsKey('editGame')) {
        isEditMode = true;
        gameToEdit = args['game'] as LotteryGame;
        lottery = Map<String, String>.from(gameToEdit!.lottery);
        selectedNumbers = List<int>.from(gameToEdit!.selectedNumbers);
        selectedTeam = gameToEdit!.selectedTeam;
      } else if (args.containsKey('addGame')) {
        isEditMode = false;
        lottery = Map<String, String>.from(args['lottery']);
      } else if (args.containsKey('lottery')) {
        lottery = Map<String, String>.from(args['lottery']);
        isEditMode = false;
      } else {
        throw Exception('Argumentos inválidos para ManualEntryScreen');
      }
    } else {
      throw Exception('Argumentos inválidos para ManualEntryScreen');
    }
  }

  void _toggleNumber(int number) {
    setState(() {
      if (selectedNumbers.contains(number)) {
        selectedNumbers.remove(number);
      } else {
        int maxSelections = _getMaxSelectableNumbers(lottery['apiName']!);
        if (selectedNumbers.length < maxSelections) {
          selectedNumbers.add(number);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Você já selecionou o máximo de $maxSelections números.')),
          );
        }
      }
    });
  }

  int _getMaxNumber(String apiName) {
    switch (apiName) {
      case 'lotofacil':
        return 25;
      case 'megasena':
        return 60;
      case 'quina':
        return 80;
      case 'lotomania':
        return 100;
      case 'timemania':
        return 80;
      case 'duplasena':
        return 50;
      case 'federal':
        return 60;
      case 'loteca':
        return 90;
      case 'diadesorte':
        return 31;
      case 'supersete':
        return 49;
      default:
        return 60;
    }
  }

  int _getMinSelectableNumbers(String apiName) {
    switch (apiName) {
      case 'lotofacil':
        return 15;
      case 'megasena':
        return 6;
      case 'quina':
        return 5;
      case 'lotomania':
        return 50;
      case 'timemania':
        return 10;
      case 'duplasena':
        return 6;
      case 'diadesorte':
        return 7;
      case 'supersete':
        return 7;
      default:
        return 6;
    }
  }

  int _getMaxSelectableNumbers(String apiName) {
    switch (apiName) {
      case 'lotofacil':
        return 18; // Lotofácil allows selection between 15 and 18 numbers
      case 'megasena':
        return 15; // Mega-Sena allows selection between 6 and 15 numbers
      case 'quina':
        return 15; // Quina allows selection between 5 and 15 numbers
      case 'lotomania':
        return 50; // Lotomania requires exactly 50 numbers
      case 'timemania':
        return 10; // Timemania requires exactly 10 numbers
      case 'duplasena':
        return 15; // Dupla Sena allows selection between 6 and 15 numbers
      case 'diadesorte':
        return 15; // Dia de Sorte allows selection between 7 and 15 numbers
      case 'supersete':
        return 7; // Super Sete requires exactly 7 numbers
      default:
        return 6;
    }
  }

  void _saveGame() {
    int minNumbers = _getMinSelectableNumbers(lottery['apiName']!);
    int maxNumbers = _getMaxSelectableNumbers(lottery['apiName']!);

    if (selectedNumbers.length < minNumbers ||
        selectedNumbers.length > maxNumbers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Por favor, selecione entre $minNumbers e $maxNumbers números.')),
      );
      return;
    }

    if (lottery['apiName'] == 'timemania' && selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um time.')),
      );
      return;
    }

    final result = {
      'lottery': lottery,
      'selectedNumbers': selectedNumbers,
      'selectedTeam': selectedTeam,
    };

    Navigator.pop(context, result);
  }

  void _viewResult() {
    int minNumbers = _getMinSelectableNumbers(lottery['apiName']!);
    int maxNumbers = _getMaxSelectableNumbers(lottery['apiName']!);

    if (selectedNumbers.length < minNumbers ||
        selectedNumbers.length > maxNumbers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Por favor, selecione entre $minNumbers e $maxNumbers números.')),
      );
      return;
    }

    AdManager.showInterstitialAd(() async {
      Navigator.pushNamed(
        context,
        '/result',
        arguments: {
          'selectedNumbers': selectedNumbers,
          'lottery': lottery,
          'selectedTeam': selectedTeam,
        },
      );
    });
  }

  void _navigateToScanTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanTicketScreen(
          returnGames: true,
          lottery: {},
        ),
      ),
    );

    if (result != null && result is List<LotteryGame>) {
      setState(() {
        if (result.isNotEmpty) {
          selectedNumbers = result.first.selectedNumbers;
          selectedTeam = result.first.selectedTeam;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum jogo foi escaneado.')),
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
                    contestNumber = contestNumberInput;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Número do concurso $contestNumberInput selecionado.')),
                  );
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
    int maxNumber = _getMaxNumber(lottery['apiName']!);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Entrada Manual',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Form for selecting numbers and team
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      lottery['name']!,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Números selecionados: ${selectedNumbers.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: maxNumber,
                      itemBuilder: (context, index) {
                        int number = index + 1;
                        bool isSelected = selectedNumbers.contains(number);
                        return GestureDetector(
                          onTap: () => _toggleNumber(number),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.green : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                number.toString(),
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (lottery['apiName'] == 'timemania') ...[
                      DropdownButtonFormField<String>(
                        value: selectedTeam,
                        hint: const Text('Selecione seu time'),
                        items: teams.map((team) {
                          return DropdownMenuItem(
                            value: team,
                            child: Text(team),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTeam = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecione um time.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.showSaveButton)
                          ElevatedButton(
                            onPressed: _saveGame,
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(150, 50)),
                            child: Text(
                                isEditMode ? 'Atualizar Jogo' : 'Salvar Jogo'),
                          ),
                        ElevatedButton(
                          onPressed: selectedNumbers.length >=
                                  _getMinSelectableNumbers(lottery['apiName']!)
                              ? _viewResult
                              : null,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(150, 50)),
                          child: const Text('Ver Resultado'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
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
