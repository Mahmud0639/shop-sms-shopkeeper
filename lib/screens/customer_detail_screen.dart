import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerDetailScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<CustomerProvider>(context, listen: false)
            .fetchCustomerDetails(widget.customerId));
  }

  // SMS তাগাদা পাঠানোর কনফার্মেশন ডায়ালগ
  void _showSmsReminderDialog(BuildContext context, dynamic customer) {
    final totalDue = customer['total_due'] ?? '0.00';
    final sampleMessage =
        "প্রিয় ${customer['name'] ?? ''}, আপনার বর্তমান মোট বাকি ৳$totalDue। দ্রুত পরিশোধ করার অনুরোধ করা হচ্ছে।";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.sms, color: Color(0xFF1E6B48)),
            SizedBox(width: 8),
            Text("SMS তাগাদা পাঠান", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("নিচের মেসেজটি কাস্টমারের মোবাইলে পাঠানো হবে:",
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                sampleMessage,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            const Text("* ওয়ালেট থেকে ১টি SMS কাটা হবে।",
                style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("বাতিল", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6B48),
            ),
            icon: const Icon(Icons.send, size: 16, color: Colors.white),
            label: const Text("পাঠিয়ে দিন", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              final custProv = Provider.of<CustomerProvider>(context, listen: false);
              final res = await custProv.sendReminderSms(widget.customerId);

              if (mounted) {
                if (res['success'] == true) {
                  // ড্যাশবোর্ডের ওয়ালেট ব্যালেন্স রিফ্রেশ
                  Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'SMS পাঠানো হয়েছে!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'SMS পাঠাতে ব্যর্থ হয়েছে!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // বাকি/জমা যোগ করার ডায়ালগ
  void _showTransactionDialog(BuildContext context, String type) {
    final amountController = TextEditingController();
    final isDue = type == 'due';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isDue ? "নতুন বাকি যোগ করুন" : "টাকা আদায়/জমা নিন",
          style: TextStyle(color: isDue ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "টাকার পরিমাণ (৳)",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("বাতিল", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDue ? Colors.red : Colors.green,
            ),
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                final custProv = Provider.of<CustomerProvider>(context, listen: false);


                // ট্রানজেকশন যোগ করা
                final bool success = await custProv.addTransaction(widget.customerId, type, amount);

                if (mounted) {
                  if (success) {
                    // ১. ড্যাশবোর্ডের SMS ওয়ালেট ও পাওনার হিসেব রিফ্রেশ করা
                    Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();

                    // ২. কাস্টমারের ডিটেইলস ও লেনদেন রিফ্রেশ করা
                    custProv.fetchCustomerDetails(widget.customerId);

                    // ৩. নোটিফিকেশন মেসেজ দেখানো
                    final String snackMessage = isDue
                        ? "বাকি যোগ করা হয়েছে ও অটো SMS ব্যাকএন্ডে প্রসেস হয়েছে!"
                        : "টাকা জমা নেওয়া হয়েছে ও অটো SMS ব্যাকএন্ডে প্রসেস হয়েছে!";

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(snackMessage),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
                /*// ট্রানজেকশন যোগ করা
                final response = await custProv.addTransaction(widget.customerId, type, amount);

                if (mounted) {
                  // ১. ড্যাশবোর্ডের SMS ওয়ালেট ও পাওনার হিসেব রিফ্রেশ করা
                  Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();

                  // ২. কাস্টমারের ডিটেইলস ও লেনদেন রিফ্রেশ করা
                  custProv.fetchCustomerDetails(widget.customerId);

                  // ৩. মেসেজ তৈরি করা (SMS গেছে কি না তা উল্লেখ করে)
                  String snackMessage = isDue ? "বাকি যোগ করা হয়েছে" : "টাকা জমা নেওয়া হয়েছে";

                  // যদি ব্যাকএন্ড রেসপন্সে অটো এসএমএস সাকসেস থাকে
                  if (response != null &&
                      response['auto_sms'] is Map &&
                      response['auto_sms']['sent'] == true) {
                    snackMessage += " এবং অটো SMS পাঠানো হয়েছে!";
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(snackMessage),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }*/
              }
            },
            child: const Text("সংরক্ষণ করুন", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custProv = Provider.of<CustomerProvider>(context);
    final customer = custProv.customerData;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(widget.customerName),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: custProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customer == null
          ? const Center(child: Text("কাস্টমারের তথ্য পাওয়া যায়নি"))
          : Column(
        children: [
          // --- Customer Summary Card ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF0F4C81),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Text(
                    widget.customerName.isNotEmpty ? widget.customerName[0] : 'C',
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  customer['phone'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text("বর্তমান মোট বাকি", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  "৳ ${customer['total_due'] ?? '0.00'}",
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // --- Action Buttons (Due / Collect) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTransactionDialog(context, 'due'),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                        label: const Text("বাকি দিন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTransactionDialog(context, 'paid'),
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                        label: const Text("জমা নিন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // --- SMS Reminder Button ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showSmsReminderDialog(context, customer),
                    icon: const Icon(Icons.sms_failed_outlined, color: Color(0xFF1E6B48)),
                    label: const Text(
                      "SMS তাগাদা পাঠান",
                      style: TextStyle(color: Color(0xFF1E6B48), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E6B48), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Transaction History Header ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("লেনদেনের ইতিহাস", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          // --- Transaction History List ---
          Expanded(
            child: custProv.transactions.isEmpty
                ? const Center(child: Text("কোনো লেনদেন পাওয়া যায়নি", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: custProv.transactions.length,
              itemBuilder: (context, index) {
                final item = custProv.transactions[index];
                final isDue = item['type'] == 'due';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDue ? Colors.red.shade50 : Colors.green.shade50,
                      child: Icon(
                        isDue ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isDue ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(
                      isDue ? "বাকি দেওয়া হয়েছে" : "টাকা জমা নেওয়া হয়েছে",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(item['date'] ?? ''),
                    trailing: Text(
                      "${isDue ? '+' : '-'} ৳ ${item['amount']}",
                      style: TextStyle(
                        color: isDue ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}