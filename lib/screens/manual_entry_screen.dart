// lib/screens/manual_entry_screen.dart
import 'package:flutter/material.dart';
import '../models/lottery_game.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_ad_widget.dart';
import 'scan_ticket_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  late Map<String, String> lottery;
  List<int> selectedNumbers = [];
  String? selectedTeam; // Para loterias que exigem seleção de time
  bool isEditMode = false;
  LotteryGame? gameToEdit;

  final _formKey = GlobalKey<FormState>();

  // Predefined list of teams for 'timemania', can be extended
  final List<String> teams = [
    'Flamengo',
    'Palmeiras',
    'São Paulo',
    'Corinthians',
    'Vasco',
    'Grêmio',
    'Internacional',
    'Botafogo',
    'Santos',
    'Atlético Mineiro',
    // Adicione mais times conforme necessário
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
      } else {
        // Assume que os argumentos são o mapa da loteria
        lottery = Map<String, String>.from(args);
      }
    } else {
      // Caso os argumentos não sejam passados corretamente
      throw Exception('Argumentos inválidos para ManualEntryScreen');
    }
  }

  void _toggleNumber(int number) {
    setState(() {
      if (selectedNumbers.contains(number)) {
        selectedNumbers.remove(number);
      } else {
        // Defina o número máximo de seleções conforme a loteria
        int maxNumbers = _getMaxNumbers();
        if (selectedNumbers.length < maxNumbers) {
          selectedNumbers.add(number);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Você já selecionou o máximo de $maxNumbers números.')),
          );
        }
      }
    });
  }

  int _getMaxNumbers() {
    switch (lottery['apiName']) {
      case 'lotofacil':
        return 18;
      case 'megasena':
        return 15;
      case 'quina':
        return 15;
      case 'lotomania':
        return 50;
      case 'timemania':
        return 10;
      case 'duplasena':
        return 15;
      case 'federal':
        return 15;
      case 'loteca':
        return 20;
      case 'diadesorte':
        return 7;
      case 'supersete':
        return 7;
      default:
        return 15;
    }
  }

  int _getMinNumbers() {
    switch (lottery['apiName']) {
      case 'lotofacil':
        return 15;
      case 'megasena':
        return 6;
      case 'quina':
        return 5;
      case 'lotomania':
        return 50; // Lotomania tem um número fixo de seleções
      case 'timemania':
        return 10; // Exemplo
      case 'duplasena':
        return 6;
      case 'federal':
        return 6;
      case 'loteca':
        return 20;
      case 'diadesorte':
        return 7;
      case 'supersete':
        return 7;
      default:
        return 6;
    }
  }

  void _saveGame() {
    if (_formKey.currentState!.validate()) {
      int minNumbers = _getMinNumbers();

      if (selectedNumbers.length < minNumbers) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Por favor, selecione pelo menos $minNumbers números.')),
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
  }

  void _viewResult() {
    Navigator.pushNamed(
      context,
      '/result',
      arguments: {
        'selectedNumbers': selectedNumbers,
        'lottery': lottery,
        'selectedTeam': selectedTeam,
      },
    );
  }

  // Adicionado para navegar até a tela de escaneamento e retornar os números
  void _navigateToScanTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanTicketScreen(returnGames: true),
      ),
    );

    if (result != null && result is List<LotteryGame>) {
      setState(() {
        if (result.isNotEmpty) {
          selectedNumbers = result.first.selectedNumbers;
          selectedTeam = result.first.selectedTeam;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar o intervalo de números com base na loteria
    int maxNumber = 60; // Padrão, ajustar conforme a loteria

    switch (lottery['apiName']) {
      case 'lotofacil':
        maxNumber = 25;
        break;
      case 'megasena':
        maxNumber = 60;
        break;
      case 'quina':
        maxNumber = 80;
        break;
      case 'lotomania':
        maxNumber = 100;
        break;
      case 'timemania':
        maxNumber = 80;
        break;
      case 'duplasena':
        maxNumber = 50;
        break;
      case 'federal':
        maxNumber = 60;
        break;
      case 'loteca':
        maxNumber = 90;
        break;
      case 'diadesorte':
        maxNumber = 31;
        break;
      case 'supersete':
        maxNumber = 7;
        break;
      default:
        maxNumber = 60;
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Entrada Manual',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Formulário para seleção de números e time
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
                    // Botão para escanear bilhete
                    ElevatedButton.icon(
                      onPressed: _navigateToScanTicket,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Adicionar Jogo por Foto'),
                    ),
                    const SizedBox(height: 16),
                    // Seleção de Números
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
                    // Seleção de Time para 'timemania'
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
                    // Botões de Salvar e Ver Resultado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed:
                              selectedNumbers.isNotEmpty ? _viewResult : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(150, 50),
                          ),
                          child: const Text('Ver Resultado'),
                        ),
                      ],
                    ),
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
