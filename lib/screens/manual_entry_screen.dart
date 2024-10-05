import 'package:flutter/material.dart';

class ManualEntryScreen extends StatefulWidget {
  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  Map<String, String>? lottery;
  List<int> _selectedNumbers = [];
  int maxNumbers = 15; // Padrão para Lotofácil
  int totalNumbers = 25; // Padrão para Lotofácil

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lottery = ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    // Ajustando para as diferentes loterias suportadas
    if (lottery!['apiName'] == 'megasena') {
      maxNumbers = 6;
      totalNumbers = 60;
    } else if (lottery!['apiName'] == 'quina') {
      maxNumbers = 5;
      totalNumbers = 80;
    } else if (lottery!['apiName'] == 'lotomania') {
      maxNumbers = 50;
      totalNumbers = 100;
    } else if (lottery!['apiName'] == 'timemania') {
      maxNumbers = 10;
      totalNumbers = 80;
    } else if (lottery!['apiName'] == 'duplasena') {
      maxNumbers = 6;
      totalNumbers = 50;
    } else if (lottery!['apiName'] == 'federal') {
      // Federal não exige seleção de números
      maxNumbers = 0;
      totalNumbers = 0;
    } else if (lottery!['apiName'] == 'loteca') {
      maxNumbers = 14;
      totalNumbers = 14;
    } else if (lottery!['apiName'] == 'diadesorte') {
      maxNumbers = 7;
      totalNumbers = 31;
    } else if (lottery!['apiName'] == 'supersete') {
      maxNumbers = 7;
      totalNumbers = 49;
    }
  }

  // Função para adicionar ou remover números selecionados
  void _onNumberSelected(int number) {
    setState(() {
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
      } else {
        if (_selectedNumbers.length < maxNumbers) {
          _selectedNumbers.add(number);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inserir Números para ${lottery!['name']}'),
      ),
      body: Column(
        children: [
          // Verifica se a loteria exige seleção de números
          if (totalNumbers > 0)
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (totalNumbers / 10).ceil(),
                ),
                itemCount: totalNumbers,
                itemBuilder: (context, index) {
                  int number = index + 1;
                  bool isSelected = _selectedNumbers.contains(number);
                  return GestureDetector(
                    onTap: () => _onNumberSelected(number),
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Botão para conferir resultados
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              child: Text('Conferir Resultados'),
              onPressed: _selectedNumbers.length == maxNumbers
                  ? () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: {
                          'selectedNumbers': _selectedNumbers,
                          'lottery': lottery,
                        },
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
