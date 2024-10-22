// lib/models/lottery_game.dart
class LotteryGame {
  final Map<String, String> lottery;
  final List<int> selectedNumbers;
  final String? selectedTeam; // For lotteries that require team selection

  LotteryGame({
    required this.lottery,
    this.selectedNumbers = const [],
    this.selectedTeam,
  });
}
