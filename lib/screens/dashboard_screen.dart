import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // অ্যাপ চালু হতেই এপিআই থেকে ডাটা লোড হবে
    Future.microtask(() =>
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProv = Provider.of<DashboardProvider>(context);

    // ১. ইউজার ব্লকড হলে এই স্ক্রিন দেখাবে
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

    // ২. ডাটা লোডিং স্ট্যাটাস
    if (dashboardProv.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = dashboardProv.dashboardData;
    final recentCustomers = (data?['recent_customers'] as List?) ?? [];

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
                // --- SMS Wallet Header Bar ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6B48),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SMS ওয়ালেট",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${data?['sms_wallet_balance'] ?? 0} SMS অবশিষ্ট",
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
                          // Navigate to Wallet Screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E6B48),
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

                // --- Add New Customer Button (Fixed Position above list) ---
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
                  children: const [
                    Text("সাম্প্রতিক কাস্টমার", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("মোট বাকি", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),

                // --- Recent Customer Items (With ShaderMask Gradient Shadow) ---
                if (recentCustomers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text("কোনো কাস্টমার পাওয়া যায়নি", style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  SizedBox(
                    height: 200, // ফিক্সড হাইট (২-৩ টি কার্ড সুন্দর দেখার জন্য)
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white,
                            Colors.transparent, // নিচের অংশ আবছা করবে
                          ],
                          stops: [0.0, 0.6, 0.85, 1.0], // নিচে হালকা শ্যাডো
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
                            item['id'], // <-- এখানে id পাঠানো হচ্ছে
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



  // পরিবর্তন করার স্থান: _buildCustomerTile মেথড
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