import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class SessionProvider extends ChangeNotifier {
  int? sessionId;
  String topic = '';
  String language = '';
  String level = '';
  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isStarting = false;
  String? error;
  DateTime? _startTime;

  Future<void> startSession(int planId) async {
    isStarting = true;
    error = null;
    messages = [];
    sessionId = null;
    notifyListeners();
    try {
      final data = await ApiService.startSession(planId);
      sessionId = data['sessionId'];
      topic = data['topic'];
      language = data['language'];
      level = data['level'];
      _startTime = DateTime.now();
      messages.add(ChatMessage(text: data['openingMessage'], isUser: false));
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Cannot connect to backend. Is the server running?';
    } finally {
      isStarting = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (sessionId == null || text.trim().isEmpty) return;
    messages.add(ChatMessage(text: text, isUser: true));
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiService.sendMessage(sessionId!, text);
      CorrectionModel? correction;
      if (data['correction'] != null) {
        correction = CorrectionModel.fromJson(data['correction']);
      }
      messages.add(ChatMessage(
        text: data['reply'],
        isUser: false,
        correction: correction,
      ));
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> endSession() async {
    if (sessionId == null) return null;
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
    try {
      final data = await ApiService.endSession(sessionId!, duration);
      return data;
    } catch (_) {
      return null;
    }
  }

  void reset() {
    sessionId = null;
    topic = '';
    messages = [];
    error = null;
    isLoading = false;
    isStarting = false;
    _startTime = null;
    notifyListeners();
  }
}
