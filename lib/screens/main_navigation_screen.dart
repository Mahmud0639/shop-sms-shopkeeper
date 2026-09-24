import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'customer_profile_screen.dart';
import 'sms_schedule_screen.dart';
import 'wallet_recharge_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ৪টি স্ক্রিনের লিস্ট
  final List<Widget> _screens = [
    const DashboardScreen(),
    const CustomerProfileScreen(
      customer: {
        'name': 'রহিম স্টোর',
        'phone': '01700000000',
        'total_due': '১,১০০.০০',
      },
    ),
    const SmsScheduleScreen(),
    const WalletRechargeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E6B48), // সবুজ থিম কালার
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'ড্যাশবোর্ড',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'প্রোফাইল',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sms_outlined),
            activeIcon: Icon(Icons.sms),
            label: 'SMS শিডিউল',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'ওয়ালেট',
          ),
        ],
      ),
    );
  }
}