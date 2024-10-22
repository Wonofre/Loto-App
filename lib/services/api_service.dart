import 'dart:convert'; // Para codificação/decodificação JSON
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lottery_result.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Fetch the latest result from Firebase Realtime Database
  Future<LotteryResult?> fetchLatestResult(String lotteryName) async {
    try {
      LotteryResult? cachedResult = await _getCachedResult(lotteryName);

      if (cachedResult != null &&
          await _isResultValid(lotteryName, cachedResult)) {
        // Se o resultado armazenado é válido, retorna do cache
        return cachedResult;
      }

      // Se o cache for inválido, busca no Firebase
      LotteryResult? firebaseResult =
          await _getCachedResultFirebase(lotteryName);

      if (firebaseResult != null) {
        // Armazena no cache local após buscar do Firebase
        await _saveToCache(lotteryName, firebaseResult);
      }

      return firebaseResult;
    } catch (e) {
      print('Erro: $e');
      return null;
    }
  }

  // Get cached result (latest) from Firebase Realtime Database
  Future<LotteryResult?> _getCachedResultFirebase(String lotteryName) async {
    final snapshot = await _dbRef.child('lotteries/$lotteryName').get();

    if (snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return LotteryResult.fromJson(data);
    }
    return null;
  }

  // Fetch a specific result by contest number from Firebase Realtime Database
  Future<LotteryResult?> fetchResultByContestNumber(
      String lotteryName, int contestNumber) async {
    try {
      final snapshot = await _dbRef
          .child('lotteries/$lotteryName/historical/$contestNumber')
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return LotteryResult.fromJson(data);
      } else {
        print('Concurso $contestNumber não encontrado para $lotteryName.');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar o concurso $contestNumber para $lotteryName: $e');
      return null;
    }
  }

  // Função para obter dados armazenados no cache local
  Future<LotteryResult?> _getCachedResult(String lotteryName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('$lotteryName-result');

    if (cachedData != null) {
      final Map<String, dynamic> data = jsonDecode(cachedData);
      final cachedResult = LotteryResult.fromJson(data);

      // Verifica se o número do concurso ou data de apuração são válidos
      if (await _isResultValid(lotteryName, cachedResult)) {
        return cachedResult;
      }
    }
    return null;
  }

  // Função para salvar dados no cache local
  Future<void> _saveToCache(String lotteryName, LotteryResult result) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Converta o LotteryResult para JSON e adicione a hora atual como 'fetchTime'
    final resultWithFetchTime = result.toJson();
    resultWithFetchTime['fetchTime'] =
        DateTime.now().toIso8601String(); // Adiciona a hora atual

    String jsonData = jsonEncode(resultWithFetchTime);
    await prefs.setString('$lotteryName-result', jsonData);
  }

  // Verifica se o resultado é válido (mesma data ou número de concurso)
  Future<bool> _isResultValid(String lotteryName, LotteryResult result) async {
    // Obter o último resultado do Firebase
    LotteryResult? latestResult = await _getCachedResultFirebase(lotteryName);

    if (latestResult != null) {
      // Comparar os números de concurso
      return result.numero == latestResult.numero;
    }

    // Se não conseguir obter o último resultado, considere o cache válido por 12 horas
    final now = DateTime.now();

    // Verifica se 'fetchTime' está presente no resultado e é uma string válida
    final cacheTime = DateTime.tryParse(result.fetchTime.toIso8601String());

    if (cacheTime != null) {
      final difference = now.difference(cacheTime).inHours;
      return difference < 12; // Cache válido por 12 horas
    }

    return false; // Se não houver 'fetchTime', o cache é considerado inválido
  }
}
