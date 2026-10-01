import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_list_screen.dart';
import 'wallet_recharge_screen.dart'; // ওয়ালেট রিচার্জ স্ক্রিন ইমপোর্ট

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProv = Provider.of<DashboardProvider>(context);

    if (dashboardProv.isBlocked) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  "অ্যাকোউন্ট সাময়িকভাবে স্থগিত!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  dashboardProv.blockReason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (dashboardProv.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = dashboardProv.dashboardData;
    final recentCustomers = (data?['recent_customers'] as List?) ?? [];
    final int smsBalance = dashboardProv.smsBalance;
    final bool isLowBalance = dashboardProv.isLowSmsBalance;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dashboardProv.fetchDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔴 ১. এসএমএস ব্যালেন্স ৫ বা তার কম হলে ওয়ার্নিং অ্যালার্ট ব্যানার
                if (isLowBalance)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            smsBalance == 0
                                ? "আপনার SMS ব্যালেন্স শেষ! কাস্টমারকে এসএমএস পাঠাতে রিচার্জ করুন।"
                                : "আপনার SMS ব্যালেন্স কমে $smsBalance টি হয়েছে! দ্রুত রিচার্জ করুন।",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- SMS Wallet Header Bar (ব্যালেন্স অনুযায়ী ডায়নামিক কালার) ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    // ব্যালেন্স ৫ বা কম হলে লালচে-কমলা কালার, না হলে সবুজ কালার
                    color: isLowBalance ? const Color(0xFFD9383A) : const Color(0xFF1E6B48),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "SMS ওয়ালেট",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              if (isLowBalance) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.error_outline, color: Colors.yellowAccent, size: 16),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$smsBalance SMS অবশিষ্ট",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WalletRechargeScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isLowBalance ? const Color(0xFFD9383A) : const Color(0xFF1E6B48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("রিচার্জ করুন", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Card 1: Today Total Due ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A00),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("আজকের মোট পাওনা", style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        "৳ ${data?['today_due'] ?? '0'}",
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // --- Card 2: Today Collected ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20BF55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("আজকের আদায়", style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        "৳ ${data?['today_paid'] ?? '0'}",
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- Add New Customer Button ---
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                      );
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      "নতুন কাস্টমার যোগ করুন",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Customer List Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("সাম্প্রতিক কাস্টমার", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomerListScreen()),
                        );
                      },
                      child: const Text("সব দেখুন >", style: TextStyle(fontSize: 14, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // --- Recent Customer Items ---
                if (recentCustomers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text("কোনো কাস্টমার পাওয়া যায়নি", style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.6, 0.85, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: recentCustomers.length,
                        itemBuilder: (context, index) {
                          final item = recentCustomers[index];
                          return _buildCustomerTile(
                            item['id'],
                            item['name'] ?? '',
                            "৳ ${item['total_due'] ?? '0'}",
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerTile(int id, String name, String amount) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(
              customerId: id,
              customerName: name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE2E8F0),
                  child: Icon(Icons.person, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            Text(
              amount,
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}