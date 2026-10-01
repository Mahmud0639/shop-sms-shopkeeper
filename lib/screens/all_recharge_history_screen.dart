import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AllRechargeHistoryScreen extends StatefulWidget {
  const AllRechargeHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AllRechargeHistoryScreen> createState() => _AllRechargeHistoryScreenState();
}

class _AllRechargeHistoryScreenState extends State<AllRechargeHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _historyList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchHistory();

    // স্ক্রোল শেষ মাথায় পৌঁছালে পরবর্তী পেজ লোড হবে
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchHistory();
      }
    });
  }

  Future<void> _fetchHistory() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.getAllRechargeHistory(_currentPage);

      if (res['success'] == true && res['data'] != null) {
        final List newItems = res['data']['data'] ?? [];
        final int lastPage = res['data']['last_page'] ?? 1;

        setState(() {
          _historyList.addAll(newItems);
          _currentPage++;
          _hasMore = _currentPage <= lastPage;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("সব রিচার্জের ইতিহাস"),
        backgroundColor: const Color(0xFF1E6B48),
      ),
      body: _historyList.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E6B48)))
          : _historyList.isEmpty
          ? const Center(child: Text("কোনো ইতিহাস পাওয়া যায়নি", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _historyList.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _historyList.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF1E6B48))),
            );
          }

          final item = _historyList[index];
          String title = "রিচার্জ (${item['sms_amount']} SMS)";
          String date = item['created_at'] != null ? item['created_at'].toString().split('T')[0] : '';
          String amount = "৳ ${item['price']}";

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
        },
      ),
    );
  }
}