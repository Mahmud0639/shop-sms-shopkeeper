import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SmsProvider with ChangeNotifier {
  bool _isLoading = false;
  List<dynamic> _schedules = [];
  Map<String, dynamic> _summary = {
    'today_pending': 0,
    'total_pending': 0,
    'total_sent': 0,
    'total_failed': 0,
  };

  bool get isLoading => _isLoading;
  List<dynamic> get schedules => _schedules;
  Map<String, dynamic> get summary => _summary;

  // শিডিউল তালিকা লোড করা
  Future<void> fetchSchedules({String status = 'all'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getSmsSchedules(status: status);
      if (res['success'] == true) {
        _schedules = res['data'] ?? [];
        if (res['summary'] != null) {
          _summary = res['summary'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // নতুন শিডিউল সেট করা
  Future<Map<String, dynamic>> createSchedule({
    required int customerId,
    required String messageBody,
    required String scheduledDate,
    String? scheduledTime,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.createSmsSchedule({
        'customer_id': customerId,
        'message_body': messageBody,
        'scheduled_date': scheduledDate,
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
      });

      if (res['success'] == true) {
        fetchSchedules(); // রিফ্রেশ
      }
      return res;
    } catch (e) {
      debugPrint('Error creating schedule: $e');
      return {'success': false, 'message': 'নেটওয়ার্ক এরর!'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // শিডিউল ক্যানসেল করা
// শিডিউল ক্যানসেল করা
  Future<Map<String, dynamic>> cancelSchedule(int id, {String currentStatus = 'all'}) async {
    try {
      final res = await ApiService.cancelSmsSchedule(id);
      if (res['success'] == true) {
        await fetchSchedules(status: currentStatus); // বর্তমান ফিল্টার অনুযায়ী রিফ্রেশ
      }
      return res;
    } catch (e) {
      debugPrint('Error cancelling schedule: $e');
      return {'success': false, 'message': 'বাতিল করতে সমস্যা হয়েছে!'};
    }
  }
}