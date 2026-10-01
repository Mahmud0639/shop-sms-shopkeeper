import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import 'all_recharge_history_screen.dart';

class WalletRechargeScreen extends StatefulWidget {
  const WalletRechargeScreen({Key? key}) : super(key: key);

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  int _selectedPackageIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  int _smsBalance = 0;
  List<dynamic> _packages = [];
  List<dynamic> _rechargeHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchScreenData();
  }

  // API থেকে স্ক্রিনের সকল ডাটা একসাথে লোড করা
  Future<void> _fetchScreenData() async {
    setState(() => _isLoading = true);
    try {
      final walletRes = await ApiService.getWalletInfo();
      final packageRes = await ApiService.getSmsPackages();

      if (mounted) {
        setState(() {
          if (walletRes['success'] == true) {
            _smsBalance = walletRes['sms_wallet_balance'] ?? 0;
            _rechargeHistory = walletRes['recharge_history'] ?? [];
          }
          if (packageRes['success'] == true) {
            _packages = packageRes['data'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ডাটা লোড করতে সমস্যা হয়েছে: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // পেমেন্ট সাবমিট করার মেথড
  Future<void> _handleRecharge() async {
    if (_packages.isEmpty) return;

    final selectedPkg = _packages[_selectedPackageIndex];

    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.rechargeWallet(
        packageName: selectedPkg['name'],
        smsAmount: int.parse(selectedPkg['sms_amount'].toString()),
        price: double.parse(selectedPkg['price'].toString()),
      );

      setState(() => _isSubmitting = false);

      if (res['success'] == true && res['payment_url'] != null) {
        String paymentUrl = res['payment_url'];

        if (!mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(paymentUrl: paymentUrl),
          ),
        );

        if (result == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('পেমেন্ট সফল হয়েছে! আপনার ওয়ালেট আপডেট করা হয়েছে।'), backgroundColor: Colors.green),
          );
          _fetchScreenData(); // সফল পেমেন্টের পর ব্যালেন্স ও ইতিহাস রিফ্রেশ
        } else if (result == 'failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('পেমেন্ট ব্যর্থ হয়েছে! আবার চেষ্টা করুন।'), backgroundColor: Colors.red),
          );
        } else if (result == 'cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('পেমেন্ট বাতিল করা হয়েছে।'), backgroundColor: Colors.orange),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'পেমেন্ট গেটওয়ে ওপেন করা সম্ভব হয়নি!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('এরর: $e'), backgroundColor: Colors.red),
      );
    }
  }
  String formatBanglaDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';

    try {
      DateTime parsedDate = DateTime.parse(rawDate);

      List<String> banglaMonths = [
        'জানুয়ারী', 'ফেব্রুয়ারী', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
        'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
      ];

      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = banglaMonths[parsedDate.month - 1];
      String year = parsedDate.year.toString();

      // ইংরেজি সংখ্যাকে বাংলা সংখ্যায় পরিবর্তন
      const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const banglaDigits  = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

      for (int i = 0; i < englishDigits.length; i++) {
        day = day.replaceAll(englishDigits[i], banglaDigits[i]);
        year = year.replaceAll(englishDigits[i], banglaDigits[i]);
      }

      return '$day $month, $year';
    } catch (e) {
      return rawDate;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6B48),
        title: const Text("SMS ওয়ালেট ও রিচার্জ"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E6B48)))
          : RefreshIndicator(
        onRefresh: _fetchScreenData,
        color: const Color(0xFF1E6B48),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Current Balance Header Card ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6B48),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const Text("অবশিষ্ট SMS", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          "$_smsBalance টি",
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Select Package Section ---
              const Text("প্যাকেজ কিনুন", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _packages.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("কোনো প্যাকেজ উপলব্ধ নেই")),
              )
                  : Row(
                children: List.generate(_packages.length, (index) {
                  final pkg = _packages[index];
                  final isSelected = _selectedPackageIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPackageIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E6B48) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${pkg['sms_amount']} SMS",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF1E6B48) : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "৳ ${pkg['price']}",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // --- Package Details Summary & Recharge Button ---
              if (_packages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("প্যাকেজ মূল্য", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            "৳ ${_packages[_selectedPackageIndex]['price']}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleRecharge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6B48),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text("রিচার্জ করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // --- Recharge History Header ---
              // --- Recharge History Header with View All Button ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("রিচার্জের ইতিহাস", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (_rechargeHistory.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AllRechargeHistoryScreen()),
                        );
                      },
                      child: const Text(
                        "সব দেখুন >",
                        style: TextStyle(color: Color(0xFF1E6B48), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              _rechargeHistory.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("এখনো কোনো রিচার্জ করা হয়নি", style: TextStyle(color: Colors.grey))),
              )
                  : Column(
                children: _rechargeHistory.map((item) {
                  String title = "রিচার্জ (${item['sms_amount']} SMS)";
                  String date = formatBanglaDate(item['created_at']);
                  String amount = "৳ ${item['price']}";

                  return _buildHistoryTile(title, date, amount);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(String title, String date, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.history, color: Color(0xFF1E6B48)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(amount, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

// Payment WebView Screen
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewScreen({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkUrlRedirect(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkUrlRedirect(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            _checkUrlRedirect(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkUrlRedirect(String url) {
    if (_isHandled) return;

    if (url.contains('/api/payment/success')) {
      _isHandled = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) Navigator.pop(context, 'success');
      });
    } else if (url.contains('/api/payment/fail')) {
      _isHandled = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) Navigator.pop(context, 'failed');
      });
    } else if (url.contains('/api/payment/cancel')) {
      _isHandled = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) Navigator.pop(context, 'cancelled');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("অনলাইন পেমেন্ট"),
        backgroundColor: const Color(0xFF1E6B48),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E6B48)),
            ),
        ],
      ),
    );
  }


}