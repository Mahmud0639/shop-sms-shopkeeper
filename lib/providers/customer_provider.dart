import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _customerData;
  List<dynamic> _transactions = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get customerData => _customerData;
  List<dynamic> get transactions => _transactions;

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
        await fetchCustomerDetails(customerId); // তালিকা ও মোট বাকি রিফ্রেশ
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