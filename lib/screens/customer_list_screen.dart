import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';
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

  // সিলেক্ট করা কাস্টমারদের ID রাখার জন্য সেট
  final Set<int> _selectedCustomerIds = {};

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

  // বাল্ক SMS তাগাদা পাঠানোর ডায়ালগ
  void _showBulkSmsDialog(List customersToSend, {required String title}) {
    final count = customersToSend.length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("কোনো কাস্টমার সিলেক্ট করা হয়নি!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_unread_rounded, color: Color(0xFF0F4C81)),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("আপনার নির্বাচন করা $count জন কাস্টমারকে তাগাদা মেসেজ পাঠানো হবে।"),
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

              final custProv = Provider.of<CustomerProvider>(context, listen: false);
              final res = await custProv.sendBulkReminderSms(
                customerIds: title.contains("সকল") ? null : _selectedCustomerIds.toList(),
                allDueCustomers: title.contains("সকল"),
              );

              if (mounted) {
                if (res['success'] == true) {
                  Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
                  custProv.fetchCustomers();
                  setState(() => _selectedCustomerIds.clear());

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'SMS সফলভাবে পাঠানো হয়েছে!'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'SMS পাঠাতে ব্যর্থ হয়েছে!'), backgroundColor: Colors.red),
                  );
                }
              }
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

    // শুধু যাদের বাকি আছে এমন কাস্টমারদের তালিকা
    final dueCustomers = custProv.customers.where((c) {
      final due = double.tryParse(c['total_due']?.toString() ?? '0') ?? 0;
      return due > 0;
    }).toList();

    // সিলেক্ট করা কাস্টমারদের ডাটা ফিল্টার
    final selectedCustomersList = custProv.customers
        .where((c) => _selectedCustomerIds.contains(c['id']))
        .toList();

    final bool isAllSelected = dueCustomers.isNotEmpty &&
        dueCustomers.every((c) => _selectedCustomerIds.contains(c['id']));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("কাস্টমার তালিকা"),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedCustomerIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: "সিলেকশন মুছুন",
              onPressed: () {
                setState(() {
                  _selectedCustomerIds.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Options Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F4C81),
            child: Column(
              children: [
                // সার্চ বক্স
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
                const SizedBox(height: 12),

                // ১. সকল বাকিদারকে একসাথে তাগাদা বাটন
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
                    onPressed: () => _showBulkSmsDialog(dueCustomers, title: "সকল বাকিদারকে তাগাদা"),
                  ),
                ),
              ],
            ),
          ),

          // ২. সিলেক্ট করার জন্য কন্ট্রোল বার (Select All & Selected Button)
          if (dueCustomers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Select All Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: isAllSelected,
                        activeColor: const Color(0xFF0F4C81),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              // সব বাকিদার সিলেক্ট করা
                              for (var c in dueCustomers) {
                                _selectedCustomerIds.add(c['id']);
                              }
                            } else {
                              _selectedCustomerIds.clear();
                            }
                          });
                        },
                      ),
                      const Text(
                        "সবাইকে সিলেক্ট করুন",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),

                  // নির্দিষ্ট কাস্টমারদের SMS সেন্ড করার বাটন (যদি সিলেক্ট করা থাকে)
                  if (_selectedCustomerIds.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.send, size: 14, color: Colors.white),
                      label: Text(
                        "সিলেক্টেড (${_selectedCustomerIds.length}) SMS",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      onPressed: () => _showBulkSmsDialog(
                        selectedCustomersList,
                        title: "সিলেক্টেড কাস্টমারদের তাগাদা",
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
                padding: const EdgeInsets.all(12),
                itemCount: custProv.customers.length,
                itemBuilder: (context, index) {
                  final customer = custProv.customers[index];
                  final int id = customer['id'];
                  final bool isSelected = _selectedCustomerIds.contains(id);
                  final double due = double.tryParse(customer['total_due']?.toString() ?? '0') ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isSelected
                          ? const BorderSide(color: Color(0xFF0F4C81), width: 1.5)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Checkbox যুক্ত করা হলো
                          Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFF0F4C81),
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedCustomerIds.add(id);
                                } else {
                                  _selectedCustomerIds.remove(id);
                                }
                              });
                            },
                          ),
                          CircleAvatar(
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
                        ],
                      ),
                      title: Text(
                        customer['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(customer['phone'] ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "মোট বাকি",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            "৳ $due",
                            style: TextStyle(
                              color: due > 0 ? Colors.orange.shade800 : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailScreen(
                              customerId: id,
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