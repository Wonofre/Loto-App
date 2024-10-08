// lib/models/lottery_result.dart
import 'dart:convert';

class LotteryResult {
  final String numero;
  final String dataApuracao;
  final List<int> listaDezenas;
  final double valorAcumuladoProximoConcurso;
  final Map<String, double> rateioPremios;

  LotteryResult({
    required this.numero,
    required this.dataApuracao,
    required this.listaDezenas,
    required this.valorAcumuladoProximoConcurso,
    required this.rateioPremios,
  });

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      numero: json['numero'] != null ? json['numero'].toString() : '',
      dataApuracao:
          json['dataApuracao'] != null ? json['dataApuracao'].toString() : '',
      listaDezenas: json['listaDezenas'] != null
          ? (json['listaDezenas'] as List)
              .map((e) => int.parse(e.toString()))
              .toList()
          : [],
      valorAcumuladoProximoConcurso: (json['valorAcumuladoProximoConcurso']
              is String)
          ? double.parse(json['valorAcumuladoProximoConcurso'])
          : (json['valorAcumuladoProximoConcurso'] as num?)?.toDouble() ?? 0.0,
      rateioPremios: json['listaRateioPremio'] != null
          ? Map.fromEntries(
              (json['listaRateioPremio'] as List).map((item) => MapEntry(
                  item['descricaoFaixa'],
                  (item['valorPremio'] is String)
                      ? double.parse(item['valorPremio'])
                      : (item['valorPremio'] is num)
                          ? item['valorPremio'].toDouble()
                          : 0.0)))
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'dataApuracao': dataApuracao,
      'listaDezenas': listaDezenas,
      'valorAcumuladoProximoConcurso': valorAcumuladoProximoConcurso,
      'rateioPremios': rateioPremios.entries
          .map((e) => {'descricaoFaixa': e.key, 'valorPremio': e.value})
          .toList(),
    };
  }
}
