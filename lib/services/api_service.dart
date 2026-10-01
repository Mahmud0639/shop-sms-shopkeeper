import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // আপনার লারাভেল লোকাল IP বা ডোমেইন URL (Android Emulator এর জন্য 10.0.2.2)
 // static const String baseUrl = 'http://10.68.144.203:8000/api';
  static const String baseUrl = 'https://blazing-awhile-childcare.ngrok-free.dev/api';
  // Header এ টোকেন যুক্ত করার মেথড
  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ১. রেজিস্ট্রেশন API
  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ২. লগইন API
  static Future<Map<String, dynamic>> login(String phone, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );
    return jsonDecode(response.body);
  }

  // Dashboard Data Fetch
  static Future<Map<String, dynamic>> getDashboardData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      // অ্যাকাউন্ট ব্লকড থাকলে রেসপন্স রিটার্ন করবে
      return jsonDecode(response.body);
    } else {
      throw Exception('ডাটা লোড করতে ব্যর্থ হয়েছে');
    }
  }

  // কাস্টমার যোগ করার API Call
  static Future<Map<String, dynamic>> addCustomer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // কাস্টমার ডিটেইলস ও লেনদেনের তালিকা আনার API Call
  static Future<Map<String, dynamic>> getCustomerDetails(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$id'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // সকল কাস্টমার তালিকা ও সার্চ করার API Call
  static Future<Map<String, dynamic>> getCustomers({String? searchQuery}) async {
    String url = '$baseUrl/customers';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      url += '?search=${Uri.encodeComponent(searchQuery)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // নতুন লেনদেন (বাকি/জমা) এন্ট্রি দেওয়ার API Call
  static Future<Map<String, dynamic>> addTransaction(int customerId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/$customerId/transaction'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ম্যানুয়াল SMS তাগাদা পাঠানোর API Call
  static Future<Map<String, dynamic>> sendReminderSms(int customerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/$customerId/send-reminder-sms'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

// ১. SMS শিডিউল তালিকা ও সামারি ডাটা আনা
  static Future<Map<String, dynamic>> getSmsSchedules({String? status}) async {
    String url = '$baseUrl/sms/schedules';
    if (status != null && status != 'all') {
      url += '?status=$status';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // ২. নতুন SMS শিডিউল তৈরি করা
  static Future<Map<String, dynamic>> createSmsSchedule(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sms/schedule'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ৩. পেন্ডিং শিডিউল বাতিল করা
// ৩. পেন্ডিং শিডিউল বাতিল করা
  static Future<Map<String, dynamic>> cancelSmsSchedule(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/sms/schedules/$id/cancel'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'বাতিল করা সম্ভব হয়নি (Error ${response.statusCode})'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'নেটওয়ার্ক এরর: $e'};
    }
  }

  // বাল্ক SMS তাগাদা পাঠানোর API Call (নতুন যুক্ত করা হয়েছে)
  static Future<Map<String, dynamic>> sendBulkReminderSms(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/send-bulk-reminder-sms'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ওয়ালেট রিচার্জ / SSLCommerz পেমেন্ট ইনিশিয়েট করার API Call
  static Future<Map<String, dynamic>> rechargeWallet({
    required String packageName,
    required int smsAmount,
    required double price,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/recharge'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'package_name': packageName,
        'sms_amount': smsAmount,
        'price': price,
      }),
    );
    return jsonDecode(response.body);
  }

  // ওয়ালেট ব্যালেন্স ও রিচার্জ ইতিহাস লোড করা
  static Future<Map<String, dynamic>> getWalletInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/info'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  // অ্যাডমিন প্যানেল থেকে প্যাকেজ লিস্ট লোড করা
  static Future<Map<String, dynamic>> getSmsPackages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/packages'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAllRechargeHistory(int page) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/all-history?page=$page'),
      headers: await _getHeaders(),
    );

    return json.decode(response.body);
  }


}