// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lottery_result.dart';

class ApiService {
  static const String baseUrl = 'https://lottolookup.com.br/api';
  static final ApiService _instance = ApiService._internal();
  final Map<String, LotteryResult> _cache = {};

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Método para obter o último resultado da loteria com cache interno
  Future<LotteryResult?> fetchLatestResult(String lotteryName) async {
    final url = Uri.parse('$baseUrl/$lotteryName/latest');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LotteryResult result = LotteryResult.fromJson(data);
        _cache[lotteryName] = result; // Armazenar no cache interno
        await _cacheResultLocal(
            lotteryName, data); // Cache local para persistência
        return result;
      } else {
        print('Erro ao obter os dados: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro: $e');
      return null;
    }
  }

  // Método para cachear o resultado localmente
  Future<void> _cacheResultLocal(
      String lotteryName, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final resultJson = json.encode(data);
    await prefs.setString('cached_$lotteryName', resultJson);
  }

  // Método para obter o resultado cacheado localmente
  Future<LotteryResult?> getCachedResult(String lotteryName) async {
    if (_cache.containsKey(lotteryName)) {
      return _cache[lotteryName];
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedResult = prefs.getString('cached_$lotteryName');
    if (cachedResult != null) {
      final data = json.decode(cachedResult);
      LotteryResult result = LotteryResult.fromJson(data);
      _cache[lotteryName] = result; // Armazenar no cache interno
      return result;
    }
    return null;
  }
}
