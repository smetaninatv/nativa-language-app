import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DashboardProvider extends ChangeNotifier {
  UserModel? user;
  List<PlanModel> plans = [];
  List<RecentSession> recentSessions = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiService.getDashboard();
      user = UserModel.fromJson(data['user']);
      plans = (data['plans'] as List).map((p) => PlanModel.fromJson(p)).toList();
      recentSessions = (data['recentSessions'] as List)
          .map((s) => RecentSession.fromJson(s))
          .toList();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Cannot connect to backend. Is the server running?';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPlan(String language, String targetLevel, int sessionsPerWeek) async {
    try {
      final data = await ApiService.createPlan(language, targetLevel, sessionsPerWeek);
      plans.add(PlanModel.fromJson(data));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }
}
