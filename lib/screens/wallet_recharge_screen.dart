import 'package:flutter/material.dart';

class WalletRechargeScreen extends StatefulWidget {
  const WalletRechargeScreen({Key? key}) : super(key: key);

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  int _selectedPackageIndex = 0;
  String _selectedPaymentMethod = 'bkash';

  final List<Map<String, dynamic>> _packages = [
    {'sms': 100, 'price': 50},
    {'sms': 500, 'price': 220},
    {'sms': 1000, 'price': 400},
  ];

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
                      Text(
                        "৳ ২৫০",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text("অবশিষ্ট SMS", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      SizedBox(height: 6),
                      Text(
                        "১০,০০০",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
                            "${pkg['price']} ৳",
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

            // --- Payment Gateway Selection ---
            const Text("বিকাশ/নগদ পেমেন্ট গেটওয়ে", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentCard('bkash', 'বিকাশ', Colors.pink.shade100, Colors.pink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentCard('nagad', 'নগদ', Colors.orange.shade100, Colors.orange),
                ),
              ],
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
                        "৳ ${_packages[_selectedPackageIndex]['price']}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger Bkash/Nagad Payment Webview
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6B48),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("রিচার্জ করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildPaymentCard(String key, String title, Color bgColor, Color activeColor) {
    final isSelected = _selectedPaymentMethod == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : Colors.black,
            ),
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