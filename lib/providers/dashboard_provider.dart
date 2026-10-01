import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isBlocked = false;
  String _blockReason = '';
  Map<String, dynamic>? _dashboardData;

  bool get isLoading => _isLoading;
  bool get isBlocked => _isBlocked;
  String get blockReason => _blockReason;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  // 🟢 এসএমএস ব্যালেন্স ৫ বা তার কম কিনা চেক করার হেলপার
  int get smsBalance {
    if (_dashboardData != null && _dashboardData!['sms_wallet_balance'] != null) {
      return int.tryParse(_dashboardData!['sms_wallet_balance'].toString()) ?? 0;
    }
    return 0;
  }

  bool get isLowSmsBalance => smsBalance <= 5;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getDashboardData();

      if (res['is_blocked'] == true) {
        _isBlocked = true;
        _blockReason = res['reason'] ?? '';
      } else if (res['success'] == true) {
        _dashboardData = res['data'];
        _isBlocked = false;
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}