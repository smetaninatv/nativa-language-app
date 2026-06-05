import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? user;
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => user != null;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiService.login(email, password);
      await ApiService.saveToken(data['token']);
      user = UserModel.fromJson(data['user']);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiService.register(name, email, password);
      await ApiService.saveToken(data['token']);
      user = UserModel.fromJson(data['user']);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    user = null;
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final token = await ApiService.getToken();
    return token != null;
  }
}
