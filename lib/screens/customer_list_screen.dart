import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sms_provider.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<CustomerProvider>(context, listen: false).fetchCustomers());
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<CustomerProvider>(context, listen: false)
          .fetchCustomers(search: query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // এক চাপে সবাইকে তাগাদা SMS পাঠানোর ডায়ালগ
  void _showBulkSmsDialog(List dueCustomers) {
    final count = dueCustomers.length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("কোনো বাকিদার কাস্টমার পাওয়া যায়নি!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.mark_email_unread_rounded, color: Color(0xFF0F4C81)),
            SizedBox(width: 8),
            Text("বাল্ক SMS তাগাদা"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("মোট $count জন বাকিদার কাস্টমারকে তাগাদা মেসেজ পাঠানো হবে।"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "মোট $count টি SMS আপনার ওয়ালেট থেকে কাটা হবে।",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F4C81)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81)),
            onPressed: () async {
              Navigator.pop(ctx);
              // এখানে বাল্ক সেন্ড প্রোভাইডার কল করতে হবে
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$count জন কাস্টমারকে তাগাদা SMS প্রসেস করা হচ্ছে...")),
              );
            },
            child: const Text("হ্যাঁ, সেন্ড করুন", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custProv = Provider.of<CustomerProvider>(context);

    // শুধু যাদের বাকি আছে তাদের ফিল্টার করা
    final dueCustomers = custProv.customers.where((c) {
      final due = double.tryParse(c['total_due']?.toString() ?? '0') ?? 0;
      return due > 0;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("কাস্টমার তালিকা"),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded),
            tooltip: "সবাইকে তাগাদা পাঠান",
            onPressed: () => _showBulkSmsDialog(dueCustomers),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Bulk Button Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F4C81),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "নাম বা মোবাইল নম্বর দিয়ে খুঁজুন...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0F4C81)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        custProv.fetchCustomers();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // এক ক্লিকে সবাইকে মেসেজ দেওয়ার বাটন
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.campaign, color: Colors.white),
                    label: Text(
                      "সব বাকিদারকে একসাথে তাগাদা দিন (${dueCustomers.length} জন)",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showBulkSmsDialog(dueCustomers),
                  ),
                ),
              ],
            ),
          ),

          // Customer List Area
          Expanded(
            child: custProv.isListLoading
                ? const Center(child: CircularProgressIndicator())
                : custProv.customers.isEmpty
                ? const Center(
              child: Text(
                "কোনো কাস্টমার পাওয়া যায়নি",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : RefreshIndicator(
              onRefresh: () => custProv.fetchCustomers(
                search: _searchController.text,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: custProv.customers.length,
                itemBuilder: (context, index) {
                  final customer = custProv.customers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE2E8F0),
                        child: Text(
                          customer['name'] != null && customer['name'].isNotEmpty
                              ? customer['name'][0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Color(0xFF0F4C81),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        customer['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(customer['phone'] ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "মোট বাকি",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            "৳ ${customer['total_due'] ?? '0'}",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailScreen(
                              customerId: customer['id'],
                              customerName: customer['name'] ?? '',
                            ),
                          ),
                        ).then((_) {
                          custProv.fetchCustomers(search: _searchController.text);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}