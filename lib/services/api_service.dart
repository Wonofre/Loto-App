import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lottery_result.dart';

class ApiService {
  static const String baseUrl = 'https://lottolookup.com.br/api';

  // Método para obter o último resultado da loteria
  static Future<LotteryResult?> fetchLatestResult(String lotteryName) async {
    final url = Uri.parse('$baseUrl/$lotteryName/latest');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cacheResult(lotteryName, data); // Cacheia o resultado
        return LotteryResult.fromJson(data);
      } else {
        print('Erro ao obter os dados: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro: $e');
      return null;
    }
  }

  // Método para cachear o resultado
  static Future<void> _cacheResult(
      String lotteryName, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final resultJson = json.encode(data);
    await prefs.setString('cached_$lotteryName', resultJson);
  }

  // Método para obter o resultado cacheado
  static Future<LotteryResult?> getCachedResult(String lotteryName) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedResult = prefs.getString('cached_$lotteryName');
    if (cachedResult != null) {
      final data = json.decode(cachedResult);
      return LotteryResult.fromJson(data);
    }
    return null;
  }
}
