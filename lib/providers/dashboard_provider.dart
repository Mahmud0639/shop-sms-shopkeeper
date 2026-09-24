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