class LotteryResult {
  final int numero; // Número do concurso
  final String dataApuracao;
  final List<String> listaDezenas;
  final double valorAcumuladoProximoConcurso;

  LotteryResult({
    required this.numero,
    required this.dataApuracao,
    required this.listaDezenas,
    required this.valorAcumuladoProximoConcurso,
  });

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      numero: json['numero'],
      dataApuracao: json['dataApuracao'],
      listaDezenas: List<String>.from(json['listaDezenas']),
      valorAcumuladoProximoConcurso:
          (json['valorAcumuladoProximoConcurso'] as num).toDouble(),
    );
  }
}
