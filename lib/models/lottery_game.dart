// lib/models/lottery_game.dart
class LotteryGame {
  final Map<String, String> lottery;
  List<int> selectedNumbers;
  String? selectedTeam; // Para loterias que exigem seleção de time

  LotteryGame({
    required this.lottery,
    this.selectedNumbers = const [],
    this.selectedTeam,
  });
}
