import 'package:flutter/material.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerProfileScreen({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6B48),
        title: Text(widget.customer['name'] ?? 'কাস্টমার প্রোফাইল'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Customer Header Card ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E6B48),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.customer['name'] ?? 'রহিম স্টোর',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.customer['phone'] ?? '01700000000',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("মোট পাওনা", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            "৳ ${widget.customer['total_due'] ?? '0'}",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.white30),
                      Column(
                        children: const [
                          Text("আদায়", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          SizedBox(height: 4),
                          Text("৳ ৫০,০০০", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // SMS Schedule Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Open SMS Schedule Screen
                      },
                      icon: const Icon(Icons.sms),
                      label: const Text("SMS রিমাইন্ডার শিডিউল"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- History List Title ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("লেনদেনের ইতিহাস", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("ফিল্টার", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            // --- History Items ---
            _buildHistoryItem("বাকি", "০১/০১/২০২৬", "৳ ১,১০০.০০", Colors.orange),
            _buildHistoryItem("আদায়", "০১/০১/২০২৬", "-৳ ৬৫০.০০", Colors.green),
            _buildHistoryItem("বাকি", "০১/০১/২০২৬", "৳ ৬৫০.০০", Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: color,
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
          Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}