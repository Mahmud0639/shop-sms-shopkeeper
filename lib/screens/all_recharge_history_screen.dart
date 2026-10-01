import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import
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

  String formatBanglaDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';

    try {
      DateTime parsedDate = DateTime.parse(rawDate);

      List<String> banglaMonths = [
        'জানুয়ারী', 'ফেব্রুয়ারী', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
        'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
      ];

      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = banglaMonths[parsedDate.month - 1];
      String year = parsedDate.year.toString();

      const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const banglaDigits  = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

      for (int i = 0; i < englishDigits.length; i++) {
        day = day.replaceAll(englishDigits[i], banglaDigits[i]);
        year = year.replaceAll(englishDigits[i], banglaDigits[i]);
      }

      return '$day $month, $year';
    } catch (e) {
      return rawDate;
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
          ? _buildHistoryShimmerLoading()
          : _historyList.isEmpty
          ? const Center(child: Text("কোনো ইতিহাস পাওয়া যায়নি", style: TextStyle(color: Colors.grey)))
          : AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _historyList.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _historyList.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 20,
                      width: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }

            final item = _historyList[index];
            String title = "রিচার্জ (${item['sms_amount']} SMS)";
            String date = formatBanglaDate(item['created_at']);
            String amount = "৳ ${item['price']}";

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
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
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer Loader for History List
  Widget _buildHistoryShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}