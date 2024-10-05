import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  // Adicionando todas as loterias suportadas
  final List<Map<String, String>> lotteries = [
    {'name': 'Lotofácil', 'apiName': 'lotofacil'},
    {'name': 'Mega-Sena', 'apiName': 'megasena'},
    {'name': 'Quina', 'apiName': 'quina'},
    {'name': 'Lotomania', 'apiName': 'lotomania'},
    {'name': 'Timemania', 'apiName': 'timemania'},
    {'name': 'Dupla Sena', 'apiName': 'duplasena'},
    {'name': 'Loteca', 'apiName': 'loteca'},
    {'name': 'Federal', 'apiName': 'federal'},
    {'name': 'Dia de Sorte', 'apiName': 'diadesorte'},
    {'name': 'Super Sete', 'apiName': 'supersete'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loterias - Resultado Fácil'),
        actions: [
          // Botão para navegar para a tela de histórico
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
            tooltip: 'Ver Histórico',
          ),
        ],
      ),
      body: Column(
        children: [
          // Exibir o botão "Ver Histórico" no topo da tela
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.history),
              label: Text('Ver Histórico'),
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lotteries.length,
              itemBuilder: (context, index) {
                final lottery = lotteries[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    title: Text(lottery['name']!),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/manual_entry',
                        arguments: lottery,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
