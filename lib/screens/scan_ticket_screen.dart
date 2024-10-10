// lib/screens/scan_ticket_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/lottery_game.dart'; // Certifique-se de ter o modelo LotteryGame
import '../widgets/custom_app_bar.dart';

class ScanTicketScreen extends StatefulWidget {
  final bool returnGames;

  const ScanTicketScreen({super.key, this.returnGames = false});

  @override
  _ScanTicketScreenState createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen> {
  final bool _debugMode = true; // Defina como 'false' para desativar os logs

  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  List<List<int>> _allExtractedGames = [];

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _isProcessing = true;
      });

      File image = File(pickedFile.path);
      await _processImage(image);
    } else {
      setState(() {
        _isProcessing = false;
      });
      if (_debugMode) print("Nenhuma imagem selecionada.");
    }
  }

  Future<void> _processImage(File image) async {
    try {
      if (_debugMode) print("Iniciando o processamento da imagem.");

      // Criar InputImage diretamente do arquivo da imagem
      final inputImage = InputImage.fromFile(image);

      // Iniciar o reconhecimento de texto
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      if (_debugMode)
        print("Texto reconhecido pelo OCR:\n${recognizedText.text}");

      // Extrair jogos do texto reconhecido
      List<List<int>> games = _extractGamesFromText(recognizedText.text);

      setState(() {
        _images.add(image);
        _allExtractedGames.addAll(games);
        _isProcessing = false;
      });

      if (games.isEmpty) {
        if (_debugMode) print("Nenhum jogo reconhecido nesta imagem.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum jogo reconhecido nesta imagem.'),
          ),
        );
      } else {
        if (_debugMode) print("Jogos reconhecidos nesta imagem: $games");
      }

      textRecognizer.close();
    } catch (e) {
      if (_debugMode) print("Erro durante o processamento da imagem: $e");
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Ocorreu um erro durante o processamento. Tente novamente.'),
        ),
      );
    }
  }

  List<List<int>> _extractGamesFromText(String text) {
    List<String> lines = text.split('\n');
    if (_debugMode) print("Linhas de texto reconhecidas: $lines");

    List<List<int>> games = [];
    List<int> currentGame = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Verificar se a linha inicia com uma letra indicando um novo jogo
      if (line.trim().startsWith(RegExp(r'^[A-Za-z]'))) {
        if (_debugMode) print("Iniciando um novo jogo na linha: $line");

        // Se já tivermos números no jogo atual, adicioná-lo à lista de jogos
        if (currentGame.length == 15) {
          games.add(List.from(currentGame));
          if (_debugMode) print("Jogo completo adicionado: $currentGame");
        } else if (currentGame.isNotEmpty) {
          if (_debugMode) print("Jogo incompleto descartado: $currentGame");
        }

        currentGame.clear();
      }

      // Extrair números da linha
      List<int> numbers = _extractNumbersFromLine(line);

      currentGame.addAll(numbers);

      // Continuar adicionando números até termos 15
      if (currentGame.length >= 15) {
        currentGame = currentGame.sublist(0, 15); // Garantir apenas 15 números
        games.add(List.from(currentGame));
        if (_debugMode) print("Jogo completo adicionado: $currentGame");
        currentGame.clear();
      }
    }

    // Verificar se há um jogo restante ao final
    if (currentGame.length == 15) {
      games.add(currentGame);
      if (_debugMode) print("Jogo completo adicionado no final: $currentGame");
    } else if (currentGame.isNotEmpty) {
      if (_debugMode)
        print("Jogo incompleto descartado no final: $currentGame");
    }

    return games;
  }

  List<int> _extractNumbersFromLine(String line) {
    if (_debugMode) print("Processando linha: $line");

    // Remover caracteres não numéricos, mas manter espaços
    String cleanedLine = line.replaceAll(RegExp(r'[^\d\s]'), '');

    // Adicionar espaço entre números concatenados (ex: "2223" -> "22 23")
    cleanedLine = cleanedLine.replaceAllMapped(
      RegExp(r'(\d{2})(?=\d)'),
      (Match m) => '${m[1]} ',
    );

    if (_debugMode) print("Linha após limpeza: $cleanedLine");

    // Extrair números de 1 ou 2 dígitos
    final RegExp regExp = RegExp(r'\b\d{1,2}\b');
    Iterable<Match> matches = regExp.allMatches(cleanedLine);

    List<int> numbers = matches
        .map((match) {
          int num = int.parse(match.group(0)!);
          if (num >= 1 && num <= 25) {
            return num;
          } else {
            return null;
          }
        })
        .whereType<int>()
        .toList();

    // Remover duplicatas
    numbers = numbers.toSet().toList();

    if (_debugMode) print("Números extraídos da linha: $numbers");
    return numbers;
  }

  void _showImageSourceSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar fonte da imagem'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Câmera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToResultMultiple() {
    if (_allExtractedGames.isNotEmpty) {
      if (widget.returnGames) {
        // Retorna os jogos para a tela anterior
        List<LotteryGame> games = _allExtractedGames.map((numbers) {
          return LotteryGame(
            lottery: {'name': 'Lotofácil', 'apiName': 'lotofacil'},
            selectedNumbers: numbers,
          );
        }).toList();

        Navigator.pop(context, games);
      } else {
        // Navega para a tela de resultados múltiplos
        List<LotteryGame> games = _allExtractedGames.map((numbers) {
          return LotteryGame(
            lottery: {'name': 'Lotofácil', 'apiName': 'lotofacil'},
            selectedNumbers: numbers,
          );
        }).toList();

        Navigator.pushNamed(
          context,
          '/result_multiple',
          arguments: {'games': games},
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum jogo acumulado para conferir.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Escanear Bilhetes'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _images.isNotEmpty
                ? SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Image.file(_images[index]),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _images.removeAt(index);
                                    // Remover os jogos extraídos desta imagem
                                    // Implementar lógica para remover jogos associados a esta imagem, se necessário
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                : const Icon(Icons.photo, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showImageSourceSelection,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Adicionar Imagem'),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator()
            else if (_allExtractedGames.isNotEmpty)
              Column(
                children: [
                  const Text(
                    'Jogos Acumulados:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _allExtractedGames.length,
                    itemBuilder: (context, index) {
                      List<int> game = _allExtractedGames[index];
                      return ListTile(
                        title: Text('Jogo ${index + 1}'),
                        subtitle: Wrap(
                          children: game.map((number) {
                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
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
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _allExtractedGames.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _navigateToResultMultiple,
                    child: const Text('Conferir Jogos Acumulados'),
                  ),
                ],
              )
            else
              const Text(
                'Nenhuma imagem selecionada ou nenhum jogo reconhecido.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
