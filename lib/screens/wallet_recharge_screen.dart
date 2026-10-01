import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart'; // আপনার API সার্ভিস ইমপোর্ট করুন

class WalletRechargeScreen extends StatefulWidget {
  const WalletRechargeScreen({Key? key}) : super(key: key);

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  int _selectedPackageIndex = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _packages = [
    {'name': 'Basic', 'sms': 100, 'price': 50.0},
    {'name': 'Standard', 'sms': 500, 'price': 220.0},
    {'name': 'Premium', 'sms': 1000, 'price': 400.0},
  ];

  // পেমেন্ট হ্যান্ডলিং মেথড
  Future<void> _handleRecharge() async {
    final selectedPkg = _packages[_selectedPackageIndex];

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.rechargeWallet(
        packageName: selectedPkg['name'],
        smsAmount: selectedPkg['sms'],
        price: selectedPkg['price'],
      );

      setState(() => _isLoading = false);

      if (res['success'] == true && res['payment_url'] != null) {
        String paymentUrl = res['payment_url'];

        // WebView স্ক্রিনে নিয়ে যাওয়া
        if (!mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(paymentUrl: paymentUrl),
          ),
        );

        // পেমেন্ট ফিল্ডের ফলাফল অনুযায়ী মেসেজ
        if (result == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('পেমেন্ট সফল হয়েছে! আপনার ওয়ালেট আপডেট করা হয়েছে।'), backgroundColor: Colors.green),
          );
          // TODO: এখানে ড্যাশবোর্ড বা ওয়ালেট ডাটা আবার রিফ্রেশ করতে পারেন
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('এরর: $e'), backgroundColor: Colors.red),
      );
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
      body: SingleChildScrollView(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("বর্তমান ব্যালেন্স", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      SizedBox(height: 6),
                      Text("৳ ২৫০", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text("অবশিষ্ট SMS", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      SizedBox(height: 6),
                      Text("১০,০০০", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Select Package Section ---
            const Text("প্যাকেজ কিনুন", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
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
                            "${pkg['sms']} SMS",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF1E6B48) : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "৳ ${pkg['price'].toInt()}",
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
                        "৳ ${_packages[_selectedPackageIndex]['price'].toInt()}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRecharge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6B48),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
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
            const Text("রিচার্জের ইতিহাস", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _buildHistoryTile("রিচার্জ (৫০০ SMS)", "১১/০২/২০২৬", "৳ ২২০.০০"),
            _buildHistoryTile("রিচার্জ (১০০ SMS)", "০১/০২/২০২৬", "৳ ৫০.০০"),
          ],
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

// ==========================================
// SSLCommerz WebView Controller Screen
// ==========================================
/*
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewScreen({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

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

  // SSLCommerz রিডাইরেক্ট ইন্টারসেপ্ট মেথড
  void _checkUrlRedirect(String url) {
    // শুধুমাত্র নির্দিষ্ট ব্যাকএন্ড রাউটে হিট করলে পপ করবে
    if (url.contains('/api/payment/success')) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, 'success');
      });
    } else if (url.contains('/api/payment/fail')) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, 'failed');
      });
    } else if (url.contains('/api/payment/cancel')) {
      Future.delayed(const Duration(milliseconds: 500), () {
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
}*/

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewScreen({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isHandled = false; // একাধিকবার পপ হওয়া আটকানোর জন্য

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

  // SSLCommerz রিডাইরেক্ট ইন্টারসেপ্ট মেথড
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
