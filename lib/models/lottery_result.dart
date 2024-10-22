import 'package:intl/intl.dart';

class LotteryResult {
  final String numero;
  final String dataApuracao;
  final List<int> listaDezenas;
  final double valorAcumuladoProximoConcurso;
  final Map<String, double> rateioPremios;
  final DateTime fetchTime; // Time when the data was fetched
  final DateTime drawDate; // Date of the lottery draw

  LotteryResult({
    required this.numero,
    required this.dataApuracao,
    required this.listaDezenas,
    required this.valorAcumuladoProximoConcurso,
    required this.rateioPremios,
    required this.fetchTime,
    required this.drawDate,
  });

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    // Helper function to parse date strings
    DateTime parseDate(String dateStr) {
      try {
        return DateFormat("dd/MM/yyyy").parse(dateStr);
      } catch (e) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return DateTime.now(); // Retorna data atual como fallback
        }
      }
    }

    return LotteryResult(
      numero: json['numero']?.toString() ?? '',
      dataApuracao: json['dataApuracao']?.toString() ?? '',
      listaDezenas: (json['listaDezenas'] as List<dynamic>?)
              ?.map((e) => int.parse(e.toString()))
              .toList() ??
          [],
      valorAcumuladoProximoConcurso: double.tryParse(
              json['valorAcumuladoProximoConcurso']?.toString() ?? '') ??
          0.0,
      rateioPremios: json['listaRateioPremio'] != null
          ? Map.fromEntries(
              (json['listaRateioPremio'] as List).map(
                (item) => MapEntry(
                  item['descricaoFaixa'].toString(),
                  double.tryParse(item['valorPremio']?.toString() ?? '') ?? 0.0,
                ),
              ),
            )
          : {},
      fetchTime: json['fetchTime'] != null
          ? DateTime.parse(json['fetchTime'])
          : DateTime.now(), // Fallback para DateTime.now()
      drawDate: parseDate(json['dataApuracao'] ?? ''), // Usa a data de apuração
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'dataApuracao': dataApuracao,
      'listaDezenas': listaDezenas,
      'valorAcumuladoProximoConcurso': valorAcumuladoProximoConcurso,
      'listaRateioPremio': rateioPremios.entries
          .map((e) => {'descricaoFaixa': e.key, 'valorPremio': e.value})
          .toList(),
      'fetchTime': fetchTime.toIso8601String(),
      'drawDate': drawDate.toIso8601String(), // Adiciona drawDate ao JSON
    };
  }
}
