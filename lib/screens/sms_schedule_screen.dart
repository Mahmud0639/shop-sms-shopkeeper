import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sms_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';

class SmsScheduleScreen extends StatefulWidget {
  const SmsScheduleScreen({Key? key}) : super(key: key);

  @override
  State<SmsScheduleScreen> createState() => _SmsScheduleScreenState();
}

class _SmsScheduleScreenState extends State<SmsScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statusFilters = ['all', 'pending', 'sent', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadSchedules();
      }
    });

    Future.microtask(() => _loadSchedules());
  }

  void _loadSchedules() {
    final status = _statusFilters[_tabController.index];
    Provider.of<SmsProvider>(context, listen: false).fetchSchedules(status: status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddScheduleBottomSheet(BuildContext context) {
    int? selectedCustomerId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0); // డిఫాల్ట్ ১০:০০ AM

    final msgController = TextEditingController(
      text: "প্রিয় কাস্টমার, আপনার বকেয়া টাকা পরিশোধের জন্য বিনীত অনুরোধ করা হচ্ছে। ধন্যবাদ।",
    );

    Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final custProv = Provider.of<CustomerProvider>(context);
            final dashProv = Provider.of<DashboardProvider>(context, listen: false);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "নতুন SMS শিডিউল যোগ করুন",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E6B48)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // কাস্টমার সিলেক্টর Dropdown
                    const Text("কাস্টমার নির্বাচন করুন", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    custProv.isListLoading
                        ? const LinearProgressIndicator()
                        : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text("কাস্টমার বেছে নিন"),
                          value: selectedCustomerId,
                          items: custProv.customers.map<DropdownMenuItem<int>>((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text("${item['name']} (${item['phone']}) - বাকি: ৳${item['total_due'] ?? '0'}"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedCustomerId = val;
                              final cust = custProv.customers.firstWhere((e) => e['id'] == val, orElse: () => null);
                              if (cust != null) {
                                msgController.text =
                                "প্রিয় ${cust['name']}, আপনার বর্তমান মোট বাকি ৳${cust['total_due'] ?? '0'}। অনুরোধপূর্বক দ্রুত পরিশোধ করুন।";
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // তারিখ ও সময় সিলেক্টর (Row)
                    Row(
                      children: [
                        // তারিখ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("পাঠানোর তারিখ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const Icon(Icons.calendar_today, color: Color(0xFF1E6B48), size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // সময় (Time Picker)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("পাঠানোর সময়", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final timePicked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (timePicked != null) {
                                    setModalState(() => selectedTime = timePicked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedTime.format(context),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const Icon(Icons.access_time, color: Color(0xFF1E6B48), size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // মেসেজ টেক্সট
                    const Text("SMS মেসেজ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: msgController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Alert Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "নির্ধারিত সময়ে ১টি SMS কাটা হবে। বর্তমান ওয়ালেট: ${dashProv.dashboardData?['sms_wallet_balance'] ?? 0} SMS",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6B48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          if (selectedCustomerId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("অনুগ্রহ করে কাস্টমার সিলেক্ট করুন!")),
                            );
                            return;
                          }

                          final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                          final timeStr = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";

                          final res = await Provider.of<SmsProvider>(context, listen: false).createSchedule(
                            customerId: selectedCustomerId!,
                            messageBody: msgController.text,
                            scheduledDate: dateStr,
                            scheduledTime: timeStr, // সময় পাঠানো হচ্ছে
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'শিডিউল যোগ হয়েছে!'),
                                backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text("শিডিউল সেভ করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsProv = Provider.of<SmsProvider>(context);
    final summary = smsProv.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6B48),
        title: const Text("SMS শিডিউল ম্যানেজমেন্ট", style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleBottomSheet(context),
        backgroundColor: const Color(0xFF1E6B48),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("নতুন শিডিউল", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Quick Overview Cards
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                _buildSummaryCard("আজকের পেন্ডিং", "${summary['today_pending'] ?? 0}", Colors.orange),
                _buildSummaryCard("মোট পেন্ডিং", "${summary['total_pending'] ?? 0}", Colors.blue),
                _buildSummaryCard("সফলভাবে প্রেরিত", "${summary['total_sent'] ?? 0}", Colors.green),
              ],
            ),
          ),

          // Filter Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E6B48),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1E6B48),
              tabs: const [
                Tab(text: "সব"),
                Tab(text: "পেন্ডিং"),
                Tab(text: "প্রেরিত"),
                Tab(text: "বাতিল"),
              ],
            ),
          ),

          // Schedules List
          Expanded(
            child: smsProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : smsProv.schedules.isEmpty
                ? const Center(child: Text("কোনো শিডিউল তথ্য পাওয়া যায়নি", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: smsProv.schedules.length,
              itemBuilder: (context, index) {
                final item = smsProv.schedules[index];
                final customer = item['customer'] ?? {};
                final status = item['status'] ?? 'pending';

                Color badgeColor = Colors.orange;
                String statusText = "পেন্ডিং";

                if (status == 'sent') {
                  badgeColor = Colors.green;
                  statusText = "প্রেরিত";
                } else if (status == 'cancelled' || status == 'failed') {
                  badgeColor = Colors.red;
                  statusText = status == 'cancelled' ? "বাতিল" : "ব্যর্থ";
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              customer['name'] ?? 'অজানা কাস্টমার',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer['phone'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['message_body'] ?? '',
                            style: const TextStyle(fontSize: 12, height: 1.3),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  "সময়: ${item['scheduled_date'] ?? ''} ${item['scheduled_time'] ?? ''}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (status == 'pending')
                              TextButton.icon(
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                label: const Text("বাতিল করুন", style: TextStyle(color: Colors.red, fontSize: 12)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("নিশ্চিত করুন"),
                                      content: const Text("আপনি কি এই SMS শিডিউলটি বাতিল করতে চান?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("না")),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text("হ্যাঁ, বাতিল করুন", style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await Provider.of<SmsProvider>(context, listen: false).cancelSchedule(item['id']);
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
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

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, color: color.withOpacity(0.9)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}