// lib/screens/scan_ticket_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/lottery_game.dart';
import '../widgets/custom_app_bar.dart';

class ScanTicketScreen extends StatefulWidget {
  final bool returnGames;
  final Map<String, String> lottery;

  const ScanTicketScreen(
      {Key? key, this.returnGames = false, required this.lottery})
      : super(key: key);

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

      final inputImage = InputImage.fromFile(image);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      if (_debugMode)
        print("Texto reconhecido pelo OCR:\n${recognizedText.text}");

      List<List<int>> games =
          _extractGamesFromText(recognizedText.text, widget.lottery);

      setState(() {
        _images.add(image);
        _allExtractedGames.addAll(games);
        _isProcessing = false;
      });

      if (games.isEmpty) {
        if (_debugMode) print("Nenhum jogo reconhecido nesta imagem.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nenhum jogo reconhecido nesta imagem.')),
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
            content: Text(
                'Ocorreu um erro durante o processamento. Tente novamente.')),
      );
    }
  }

  List<List<int>> _extractGamesFromText(
      String text, Map<String, String> lottery) {
    int expectedNumbersPerGame =
        _getExpectedNumbersPerGame(lottery['apiName']!);
    List<String> lines = text.split('\n');
    if (_debugMode) print("Linhas de texto reconhecidas: $lines");

    List<List<int>> games = [];
    List<int> currentGame = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.trim().startsWith(RegExp(r'^[A-Za-z]'))) {
        if (_debugMode) print("Iniciando um novo jogo na linha: $line");

        if (currentGame.length == expectedNumbersPerGame) {
          games.add(List.from(currentGame));
          if (_debugMode) print("Jogo completo adicionado: $currentGame");
        } else if (currentGame.isNotEmpty) {
          if (_debugMode) print("Jogo incompleto descartado: $currentGame");
        }

        currentGame.clear();
      }

      List<int> numbers = _extractNumbersFromLine(line, expectedNumbersPerGame);

      currentGame.addAll(numbers);

      if (currentGame.length >= expectedNumbersPerGame) {
        currentGame = currentGame.sublist(0, expectedNumbersPerGame);
        games.add(List.from(currentGame));
        if (_debugMode) print("Jogo completo adicionado: $currentGame");
        currentGame.clear();
      }
    }

    if (currentGame.length == expectedNumbersPerGame) {
      games.add(currentGame);
      if (_debugMode) print("Jogo completo adicionado no final: $currentGame");
    } else if (currentGame.isNotEmpty) {
      if (_debugMode)
        print("Jogo incompleto descartado no final: $currentGame");
    }

    return games;
  }

  int _getExpectedNumbersPerGame(String apiName) {
    switch (apiName) {
      case 'lotofacil':
        return 15; // Lotofácil default
      case 'megasena':
        return 6; // Mega-Sena default
      case 'quina':
        return 5; // Quina default
      case 'lotomania':
        return 50; // Lotomania fixed 50 numbers
      case 'timemania':
        return 10; // Timemania fixed 10 numbers
      case 'duplasena':
        return 6; // Dupla Sena default
      case 'diadesorte':
        return 7; // Dia de Sorte default
      case 'supersete':
        return 7; // Super Sete fixed 7 numbers
      default:
        return 6;
    }
  }

  List<int> _extractNumbersFromLine(String line, int expectedNumbersPerGame) {
    if (_debugMode) print("Processando linha: $line");

    String cleanedLine = line.replaceAll(RegExp(r'[^\d\s]'), '');

    cleanedLine = cleanedLine.replaceAllMapped(
      RegExp(r'(\d{2})(?=\d)'),
      (Match m) => '${m[1]} ',
    );

    if (_debugMode) print("Linha após limpeza: $cleanedLine");

    final RegExp regExp = RegExp(r'\b\d{1,2}\b');
    Iterable<Match> matches = regExp.allMatches(cleanedLine);

    List<int> numbers = matches
        .map((match) {
          int num = int.parse(match.group(0)!);
          if (num >= 1 && num <= _getMaxNumber(widget.lottery['apiName']!)) {
            return num;
          } else {
            return null;
          }
        })
        .whereType<int>()
        .toList();

    numbers = numbers.toSet().toList();

    if (_debugMode) print("Números extraídos da linha: $numbers");
    return numbers;
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
      case 'diadesorte':
        return 31;
      case 'supersete':
        return 49;
      default:
        return 60;
    }
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
        List<LotteryGame> games = _allExtractedGames.map((numbers) {
          return LotteryGame(lottery: widget.lottery, selectedNumbers: numbers);
        }).toList();

        Navigator.pop(context, games);
      } else {
        List<LotteryGame> games = _allExtractedGames.map((numbers) {
          return LotteryGame(lottery: widget.lottery, selectedNumbers: numbers);
        }).toList();

        Navigator.pushNamed(
          context,
          '/result_multiple',
          arguments: {'games': games},
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum jogo acumulado para conferir.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Escanear Bilhetes'),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Menu suspenso de instruções
                  ExpansionTile(
                    initiallyExpanded: _images
                        .isEmpty, // Expande por padrão se não houver imagens
                    title: const Text(
                      'Instruções',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '- Garanta que o bilhete esteja bem iluminado e centralizado.',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Text(
                              '- Tente enquadrar apenas a área dos jogos como destacado na imagem abaixo.',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),

                            // Adicionando a imagem de exemplo com o quadrado vermelho e flecha ao lado
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/Bilhete-Instruções.jpg', // Coloque o caminho correto da imagem no seu projeto
                                    height: 200,
                                  ),
                                  const SizedBox(width: 20),
                                  Image.asset(
                                    'assets/images/Bilhete-Instrucoes-Detalhe.jpg', // Caminho correto para a imagem do detalhe
                                    height: 120, // Tamanho da imagem do detalhe
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Exibição das imagens selecionadas
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
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _images.removeAt(index);
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
                  if (_allExtractedGames.isNotEmpty)
                    Column(
                      children: [
                        const Text(
                          'Jogos Acumulados:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _allExtractedGames.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
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
