import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import
import '../services/api_service.dart';
import 'all_recharge_history_screen.dart';

class WalletRechargeScreen extends StatefulWidget {
  const WalletRechargeScreen({Key? key}) : super(key: key);

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPackageIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  int _smsBalance = 0;
  List<dynamic> _packages = [];
  List<dynamic> _rechargeHistory = [];

  // Controllers
  late ConfettiController _confettiController;
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fetchScreenData();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

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
          SnackBar(
              content: Text('ডাটা লোড করতে সমস্যা হয়েছে: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _toBanglaNumber(int number) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    String strNumber = number.toString();
    for (int i = 0; i < englishDigits.length; i++) {
      strNumber = strNumber.replaceAll(englishDigits[i], banglaDigits[i]);
    }
    return strNumber;
  }

  void _showSuccessDialog() {
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.check_circle_rounded,
                      color: Color(0xFF1E6B48), size: 50),
                ),
                const SizedBox(height: 16),
                const Text(
                  "পেমেন্ট সফল হয়েছে!",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E6B48)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "আপনার রিচার্জ সফলভাবে সম্পন্ন হয়েছে এবং ওয়ালেট ব্যালেন্স আপডেট করা হয়েছে।",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6B48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ঠিক আছে",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
          _fetchScreenData();
          _showSuccessDialog();
        } else if (result == 'failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('পেমেন্ট ব্যর্থ হয়েছে! আবার চেষ্টা করুন।'),
                backgroundColor: Colors.red),
          );
        } else if (result == 'cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('পেমেন্ট বাতিল করা হয়েছে।'),
                backgroundColor: Colors.orange),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text(res['message'] ?? 'পেমেন্ট গেটওয়ে ওপেন করা সম্ভব হয়নি!'),
              backgroundColor: Colors.red),
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
        'জানুয়ারী',
        'ফেব্রুয়ারী',
        'মার্চ',
        'এপ্রিল',
        'মে',
        'জুন',
        'জুলাই',
        'আগস্ট',
        'সেপ্টেম্বর',
        'অক্টোবর',
        'নভেম্বর',
        'ডিসেম্বর'
      ];

      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = banglaMonths[parsedDate.month - 1];
      String year = parsedDate.year.toString();

      const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

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
      body: Stack(
        children: [
          _isLoading
              ? _buildWalletShimmerLoading()
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
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F4C3A),
                          Color(0xFF1E6B48),
                          Color(0xFF27855C)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          const Color(0xFF1E6B48).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Background Animation Bubble
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _bgAnimationController,
                              builder: (context, child) {
                                double value =
                                    _bgAnimationController.value;
                                return Stack(
                                  children: [
                                    Positioned(
                                      top: -35 + (value * 15),
                                      right: -35 + (value * 10),
                                      child: Transform.scale(
                                        scale: 1.0 + (value * 0.12),
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white
                                                .withOpacity(0.08),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -25 - (value * 10),
                                      left: -25 + (value * 15),
                                      child: Transform.scale(
                                        scale: 1.1 - (value * 0.12),
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white
                                                .withOpacity(0.05),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Main Content Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                    Colors.white.withOpacity(0.15),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "অবশিষ্ট SMS",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: _smsBalance.toDouble()),
                                  duration: const Duration(seconds: 3),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Text(
                                      "${_toBanglaNumber(value.toInt())} টি",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Select Package Section ---
                  const Text("প্যাকেজ কিনুন",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  _packages.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text("কোনো প্যাকেজ উপলব্ধ নেই")),
                  )
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      double cardWidth =
                          (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_packages.length,
                                (index) {
                              final pkg = _packages[index];
                              final isSelected =
                                  _selectedPackageIndex == index;

                              return SizedBox(
                                width: cardWidth,
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => setState(() =>
                                    _selectedPackageIndex = index),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE8F5E9)
                                            : Colors.white,
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF1E6B48)
                                              : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                          BoxShadow(
                                            color: const Color(
                                                0xFF1E6B48)
                                                .withOpacity(
                                                0.18),
                                            blurRadius: 10,
                                            offset: const Offset(
                                                0, 4),
                                          ),
                                        ]
                                            : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(
                                                0.02),
                                            blurRadius: 4,
                                            offset: const Offset(
                                                0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisSize:
                                              MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "${pkg['sms_amount']} SMS",
                                                  style: TextStyle(
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    fontSize: isSelected
                                                        ? 15
                                                        : 14,
                                                    color: isSelected
                                                        ? const Color(
                                                        0xFF1E6B48)
                                                        : Colors
                                                        .black87,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: 6),
                                                Text(
                                                  "৳ ${pkg['price']}",
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? const Color(
                                                        0xFF1E6B48)
                                                        : Colors.grey
                                                        .shade600,
                                                    fontSize: 13,
                                                    fontWeight:
                                                    isSelected
                                                        ? FontWeight
                                                        .w600
                                                        : FontWeight
                                                        .normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              top: -10,
                                              right: -2,
                                              child: Container(
                                                padding:
                                                const EdgeInsets
                                                    .all(2),
                                                decoration:
                                                const BoxDecoration(
                                                  color: Color(
                                                      0xFF1E6B48),
                                                  shape:
                                                  BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Package Details Summary & Recharge Button ---
                  if (_packages.isNotEmpty &&
                      _selectedPackageIndex < _packages.length)
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
                              const Text("প্যাকেজ মূল্য",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text(
                                "৳ ${_packages[_selectedPackageIndex]['price']}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed:
                            _isSubmitting ? null : _handleRecharge,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E6B48),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2),
                            )
                                : const Text("রিচার্জ করুন",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // --- Recharge History Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("রিচার্জের ইতিহাস",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_rechargeHistory.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const AllRechargeHistoryScreen()),
                            );
                          },
                          child: const Text(
                            "সব দেখুন >",
                            style: TextStyle(
                                color: Color(0xFF1E6B48),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // --- Staggered Animated History List ---
                  _rechargeHistory.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text("এখনো কোনো রিচার্জ করা হয়নি",
                            style: TextStyle(color: Colors.grey))),
                  )
                      : AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: widget,
                          ),
                        ),
                        children: _rechargeHistory.map((item) {
                          String title =
                              "রিচার্জ (${item['sms_amount']} SMS)";
                          String date =
                          formatBanglaDate(item['created_at']);
                          String amount = "৳ ${item['price']}";

                          return _buildHistoryTile(title, date, amount);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.amber,
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(center: Offset.zero, radius: 6));
                return path;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 90,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 24),
            Container(height: 16, width: 120, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                  3,
                      (index) => Expanded(
                    child: Container(
                      height: 70,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )),
            ),
            const SizedBox(height: 20),
            Container(
                height: 60,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 28),
            Container(height: 16, width: 140, color: Colors.white),
            const SizedBox(height: 12),
            Column(
              children: List.generate(
                  4,
                      (index) => Container(
                    height: 55,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8)),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(String title, String date, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(date,
                      style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(amount,
              style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

// Payment WebView Screen
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewScreen({Key? key, required this.paymentUrl})
      : super(key: key);

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