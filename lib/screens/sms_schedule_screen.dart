import 'package:flutter/material.dart';

class SmsScheduleScreen extends StatefulWidget {
  const SmsScheduleScreen({Key? key}) : super(key: key);

  @override
  State<SmsScheduleScreen> createState() => _SmsScheduleScreenState();
}

class _SmsScheduleScreenState extends State<SmsScheduleScreen> {
  final TextEditingController _msgController = TextEditingController(
    text: "সুধী কাস্টমার, আপনার [কোম্পানির নাম] থেকে বকেয়া টাকা পরিশোধ করার জন্য বিনীত অনুরোধ করছি। ধন্যবাদ।",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6B48),
        title: const Text("SMS রিমাইন্ডার শিডিউল"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select কাস্টমার", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: "রহিম স্টোর",
                  items: const [
                    DropdownMenuItem(value: "রহিম স্টোর", child: Text("রহিম স্টোর")),
                  ],
                  onChanged: (val) {},
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text("SMS Template", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _msgController,
              maxLines: 4,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),

            // Credit Deduction Alert Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_box, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "এই মেসেজের খরচ: [১টি SMS খরচ]\nআপনার ওয়ালেট ব্যালেন্স: [১০,০০০ SMS]",
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker Placeholder
            Row(
              children: [
                Checkbox(value: true, onChanged: (v) {}),
                const Text("৩ দিন আগে"),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("এসএমএস চার্জ আপনার ওয়ালেট থেকে কাটি হবে", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Submit API Call
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6B48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("শিডিউল নিশ্চিত করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}