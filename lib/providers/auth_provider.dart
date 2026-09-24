import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // লগইন হ্যান্ডলার
  Future<bool> login(String phone, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.login(phone, pin);
      _isLoading = false;

      // ব্যাকএন্ডের 'success' ফিল্ড চেক করা হচ্ছে
      if (res['success'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', res['token']);
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'লগইন ব্যর্থ হয়েছে';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'নেটওয়ার্ক সমস্যা! আবার চেষ্টা করুন।';
      notifyListeners();
      return false;
    }
  }

  // রেজিস্ট্রেশন হ্যান্ডলার
  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.register(data);
      _isLoading = false;

      // ব্যাকএন্ডের 'success' ফিল্ড চেক করা হচ্ছে
      if (res['success'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', res['token']);
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'রেজিস্ট্রেশন ব্যর্থ হয়েছে';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'নেটওয়ার্ক সমস্যা! আবার চেষ্টা করুন।';
      notifyListeners();
      return false;
    }
  }

  // লগআউট
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}