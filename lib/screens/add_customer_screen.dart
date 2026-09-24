import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/dashboard_provider.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _openingDueController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _nidController = TextEditingController();
  final TextEditingController _refNameController = TextEditingController();
  final TextEditingController _refPhoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> customerData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'alternate_phone': _altPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'opening_due': _openingDueController.text.isEmpty ? '0' : _openingDueController.text.trim(),
        'credit_limit': _creditLimitController.text.trim(),
        'nid_number': _nidController.text.trim(),
        'reference_name': _refNameController.text.trim(),
        'reference_phone': _refPhoneController.text.trim(),
        'note': _noteController.text.trim(),
      };

      final response = await ApiService.addCustomer(customerData);

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'কাস্টমার যোগ সম্পন্ন হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );

        // ড্যাশবোর্ডের ডাটা রিফ্রেশ করা
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();

        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'কাস্টমার যোগ করতে ব্যর্থ হয়েছে'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সার্ভারে সমস্যা হয়েছে, আবার চেষ্টা করুন'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন কাস্টমার যোগ করুন', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F4C81),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("জরুরি তথ্য", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'কাস্টমারের নাম *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'মোবাইল নম্বর *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'মোবাইল নম্বর লিখুন' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _openingDueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'পূর্বের বাকি/প্রারম্ভিক বাকি (৳)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'ঠিকানা', border: OutlineInputBorder()),
              ),

              const SizedBox(height: 20),
              const Text("অতিরিক্ত ও রেফারেন্স তথ্য (ঐচ্ছিক)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              TextFormField(
                controller: _altPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'বিকল্প মোবাইল নম্বর', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _creditLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'বাকির সীমা / Credit Limit (৳)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nidController,
                decoration: const InputDecoration(labelText: 'এনআইডি নম্বর', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _refNameController,
                decoration: const InputDecoration(labelText: 'রেফারেন্স ব্যক্তির নাম', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _refPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'রেফারেন্স ব্যক্তির নম্বর', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'নোট বা মন্তব্য', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('সেভ করুন', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}