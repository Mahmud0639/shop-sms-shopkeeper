import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/location_dropdown_widget.dart';
import 'main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  // কাস্টম উইজেট থেকে পাওয়া আইডিগুলো সেভ করার ভ্যারিয়েবল
  String? _selectedDivisionId;
  String? _selectedDistrictId;
  String? _selectedUpazilaId;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_selectedDivisionId == null || _selectedDistrictId == null || _selectedUpazilaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে বিভাগ, জেলা ও উপজেলা নির্বাচন করুন')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Map<String, dynamic> data = {
      'shop_name': _shopNameController.text.trim(),
      'owner_name': _ownerNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'pin': _pinController.text.trim(),
      'division_id': _selectedDivisionId,
      'district_id': _selectedDistrictId,
      'upazila_id': _selectedUpazilaId,
    };

    bool success = await authProvider.register(data);

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'রেজিস্ট্রেশন করতে সমস্যা হয়েছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('নতুন শপ রেজিস্ট্রেশন')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'দোকানের নাম', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: 'মালিকের নাম', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'মোবাইল নম্বর', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '৪ ডিজিটের পিন (PIN)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // ১টি উইজেটের ভেতরেই বিভাগ, জেলা ও উপজেলা ড্রপডাউন চলে আসবে
              LocationDropdownWidget(
                onLocationSelected: (divisionId, districtId, upazilaId) {
                  _selectedDivisionId = divisionId;
                  _selectedDistrictId = districtId;
                  _selectedUpazilaId = upazilaId;
                },
              ),
              const SizedBox(height: 25),

              authProvider.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                ),
                onPressed: _handleRegister,
                child: const Text('রেজিস্টার করুন', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}