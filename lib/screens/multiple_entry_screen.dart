// lib/screens/multiple_entry_screen.dart
import 'package:flutter/material.dart';
import '../models/lottery_game.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/ad_manager.dart';
import '../widgets/banner_ad_widget.dart';
import 'scan_ticket_screen.dart';
import 'manual_entry_screen.dart';

class MultipleEntryScreen extends StatefulWidget {
  const MultipleEntryScreen({super.key});

  @override
  _MultipleEntryScreenState createState() => _MultipleEntryScreenState();
}

class _MultipleEntryScreenState extends State<MultipleEntryScreen> {
  Map<String, String>? lottery;

  List<LotteryGame> games = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    if (args != null && args.containsKey('apiName')) {
      lottery = args;
    } else {
      // If no lottery argument, default to Lotofácil
      lottery = {'name': 'Lotofácil', 'apiName': 'lotofacil'};
    }
  }

  void _addGame(LotteryGame game) {
    setState(() {
      games.add(game);
    });
  }

  void _removeGame(int index) {
    setState(() {
      games.removeAt(index);
    });
  }

  Future<void> _navigateToAddGame() async {
    final result = await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Adicionar Jogo Manualmente'),
              onTap: () async {
                await AdManager.showInterstitialAd(() async {
                  Navigator.pop(context); // Close the modal
                  final manualResult = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ManualEntryScreen(showSaveButton: true),
                      settings: RouteSettings(arguments: {
                        'addGame': true,
                        'lottery': lottery,
                      }),
                    ),
                  );
                  if (manualResult != null &&
                      manualResult is Map<String, dynamic>) {
                    setState(() {
                      _addGame(
                        LotteryGame(
                          lottery:
                              Map<String, String>.from(manualResult['lottery']),
                          selectedNumbers:
                              List<int>.from(manualResult['selectedNumbers']),
                          selectedTeam: manualResult['selectedTeam'],
                        ),
                      );
                    });
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Adicionar Jogos por Fotos'),
              onTap: () async {
                await AdManager.showInterstitialAd(() async {
                  Navigator.pop(context); // Close the modal
                  final scanResult = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanTicketScreen(
                          returnGames: true, lottery: lottery!),
                    ),
                  );
                  if (scanResult != null && scanResult is List<LotteryGame>) {
                    setState(() {
                      games.addAll(scanResult);
                    });
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _checkResults() {
    Navigator.pushNamed(
      context,
      '/result_multiple',
      arguments: {'games': games},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Conferir Múltiplos Jogos - ${lottery!['name']}',
      ),
      body: Column(
        children: [
          Expanded(
            child: games.isNotEmpty
                ? ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return Card(
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
                              game.lottery['name']![0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            game.lottery['name']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            'Números: ${game.selectedNumbers.join(', ')}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeGame(index),
                          ),
                          onTap: () async {
                            // Navigate to edit the game
                            final updatedGame = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ManualEntryScreen(
                                    showSaveButton: true),
                                settings: RouteSettings(arguments: {
                                  'editGame': true,
                                  'game': game,
                                  'lottery': game.lottery,
                                }),
                              ),
                            );

                            if (updatedGame != null &&
                                updatedGame is Map<String, dynamic>) {
                              setState(() {
                                games[index] = LotteryGame(
                                  lottery: Map<String, String>.from(
                                      updatedGame['lottery']),
                                  selectedNumbers: List<int>.from(
                                      updatedGame['selectedNumbers']),
                                  selectedTeam: updatedGame['selectedTeam'],
                                );
                              });
                            }
                          },
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Nenhum jogo adicionado.',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Jogo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _navigateToAddGame,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: games.isNotEmpty ? _checkResults : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Conferir Resultados',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
