import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _customerData;
  List<dynamic> _transactions = [];

  // কাস্টমার সার্চ ও অল লিস্টের জন্য নতুন স্টেট
  List<dynamic> _customers = [];
  bool _isListLoading = false;

  bool get isLoading => _isLoading;
  bool get isListLoading => _isListLoading;
  Map<String, dynamic>? get customerData => _customerData;
  List<dynamic> get transactions => _transactions;
  List<dynamic> get customers => _customers;

  // সকল কাস্টমার তালিকা আনা (সার্চ ফিচারসহ)
  Future<void> fetchCustomers({String? search}) async {
    _isListLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getCustomers(searchQuery: search);
      if (res['success'] == true) {
        _customers = res['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching customers list: $e');
    } finally {
      _isListLoading = false;
      notifyListeners();
    }
  }

  // কাস্টমারের তথ্য ও লেনদেন লোড করা
  Future<void> fetchCustomerDetails(int customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getCustomerDetails(customerId);
      if (res['success'] == true) {
        _customerData = res['data'];
        _transactions = res['data']['transactions'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching customer details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // SMS তাগাদা পাঠানোর মেথড
  Future<Map<String, dynamic>> sendReminderSms(int customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.sendReminderSms(customerId);
      return res;
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return {'success': false, 'message': 'নেটওয়ার্ক সমস্যা! আবার চেষ্টা করুন।'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // নতুন ট্রানজেকশন (বাকি/আদায়) যোগ করা
  Future<bool> addTransaction(int customerId, String type, double amount) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.addTransaction(customerId, {
        'type': type,
        'amount': amount,
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      if (res['success'] == true) {
        await fetchCustomerDetails(customerId); // রিফ্রেশ
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}