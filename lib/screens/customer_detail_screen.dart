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
                final success = await custProv.addTransaction(widget.customerId, type, amount);

                if (success && mounted) {
                  // ড্যাশবোর্ড ডাটা রিফ্রেশ করা
                  Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isDue ? "বাকি যোগ করা হয়েছে" : "টাকা জমা নেওয়া হয়েছে")),
                  );
                }
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
            child: Row(
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