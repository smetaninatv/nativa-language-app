import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  // ── Token storage ────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw ApiException(data['error'] ?? 'Request failed');
    return data;
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw ApiException(data['error'] ?? 'Request failed');
    return data;
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(String name, String email, String password) =>
      _post('/auth/register', {'name': name, 'email': email, 'password': password});

  static Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() => _get('/plans/dashboard');

  // ── Plans ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createPlan(
          String language, String targetLevel, int sessionsPerWeek) =>
      _post('/plans', {'language': language, 'targetLevel': targetLevel, 'sessionsPerWeek': sessionsPerWeek});

  // ── Sessions ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> startSession(int planId) =>
      _post('/sessions/start', {'planId': planId});

  static Future<Map<String, dynamic>> sendMessage(int sessionId, String text) =>
      _post('/sessions/$sessionId/message', {'text': text});

  static Future<Map<String, dynamic>> endSession(int sessionId, int durationSeconds) =>
      _post('/sessions/$sessionId/end', {'durationSeconds': durationSeconds});

  // ── Health ────────────────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('http://localhost:5000/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
