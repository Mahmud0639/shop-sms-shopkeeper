import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocationDropdownWidget extends StatefulWidget {
  final Function(String? divisionId, String? districtId, String? upazilaId) onLocationSelected;

  const LocationDropdownWidget({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _LocationDropdownWidgetState createState() => _LocationDropdownWidgetState();
}

class _LocationDropdownWidgetState extends State<LocationDropdownWidget> {
  List<dynamic> allDivisions = [];
  List<dynamic> allDistricts = [];
  List<dynamic> allUpazilas = [];

  List<dynamic> filteredDistricts = [];
  List<dynamic> filteredUpazilas = [];

  Map<String, dynamic>? selectedDivision;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedUpazila;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllJsonData();
  }

  // ৩টি JSON ফাইল একসাথে লোড করা
  Future<void> _loadAllJsonData() async {
    try {
      final String divString = await rootBundle.loadString('assets/divisions.json');
      final String distString = await rootBundle.loadString('assets/districts.json');
      final String upzString = await rootBundle.loadString('assets/upazilas.json');

      final rawDiv = jsonDecode(divString);
      final rawDist = jsonDecode(distString);
      final rawUpz = jsonDecode(upzString);

      setState(() {
        allDivisions = rawDiv.firstWhere((e) => e['type'] == 'table')['data'] ?? [];
        allDistricts = rawDist.firstWhere((e) => e['type'] == 'table')['data'] ?? [];
        allUpazilas = rawUpz.firstWhere((e) => e['type'] == 'table')['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      print("JSON ফাইল লোড করতে সমস্যা হয়েছে: $e");
      setState(() => isLoading = false);
    }
  }

  // সার্চযোগ্য বটম শিট ফিল্টার ডায়ালগ
  void _showSearchableBottomSheet({
    required String title,
    required List<dynamic> items,
    required Function(Map<String, dynamic>) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<dynamic> searchResults = List.from(items);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // হেডার ও ক্লোজ বাটন
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // সার্চবার
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'খুঁজুন...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        searchResults = items.where((item) {
                          final name = (item['bn_name'] ?? item['name'] ?? '').toString().toLowerCase();
                          return name.contains(query.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // রেজাল্ট লিস্ট (স্ক্রোলযোগ্য)
                  Expanded(
                    child: searchResults.isEmpty
                        ? const Center(child: Text('কোন তথ্য পাওয়া যায়নি'))
                        : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        return ListTile(
                          title: Text(item['bn_name'] ?? item['name'] ?? ''),
                          onTap: () {
                            onSelect(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _notifyParent() {
    widget.onLocationSelected(
      selectedDivision?['id']?.toString(),
      selectedDistrict?['id']?.toString(),
      selectedUpazila?['id']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // ১. বিভাগ সিলেক্ট বাটন
        _buildCustomSelectorField(
          label: 'বিভাগ',
          hint: selectedDivision?['bn_name'] ?? selectedDivision?['name'] ?? 'বিভাগ নির্বাচন করুন',
          isSelected: selectedDivision != null,
          enabled: true,
          onTap: () {
            _showSearchableBottomSheet(
              title: 'বিভাগ নির্বাচন করুন',
              items: allDivisions,
              onSelect: (item) {
                setState(() {
                  selectedDivision = item;
                  selectedDistrict = null;
                  selectedUpazila = null;
                  filteredDistricts = allDistricts
                      .where((d) => d['division_id'].toString() == item['id'].toString())
                      .toList();
                  filteredUpazilas = [];
                });
                _notifyParent();
              },
            );
          },
        ),
        const SizedBox(height: 15),

        // ২. জেলা সিলেক্ট বাটন
        _buildCustomSelectorField(
          label: 'জেলা',
          hint: selectedDistrict?['bn_name'] ?? selectedDistrict?['name'] ?? 'জেলা নির্বাচন করুন',
          isSelected: selectedDistrict != null,
          enabled: selectedDivision != null,
          onTap: () {
            _showSearchableBottomSheet(
              title: 'জেলা নির্বাচন করুন',
              items: filteredDistricts,
              onSelect: (item) {
                setState(() {
                  selectedDistrict = item;
                  selectedUpazila = null;
                  filteredUpazilas = allUpazilas
                      .where((u) => u['district_id'].toString() == item['id'].toString())
                      .toList();
                });
                _notifyParent();
              },
            );
          },
        ),
        const SizedBox(height: 15),

        // ৩. উপজেলা সিলেক্ট বাটন
        _buildCustomSelectorField(
          label: 'উপজেলা',
          hint: selectedUpazila?['bn_name'] ?? selectedUpazila?['name'] ?? 'উপজেলা নির্বাচন করুন',
          isSelected: selectedUpazila != null,
          enabled: selectedDistrict != null,
          onTap: () {
            _showSearchableBottomSheet(
              title: 'উপজেলা নির্বাচন করুন',
              items: filteredUpazilas,
              onSelect: (item) {
                setState(() {
                  selectedUpazila = item;
                });
                _notifyParent();
              },
            );
          },
        ),
      ],
    );
  }

  // কাস্টম ফিল্ড উইজেট
  Widget _buildCustomSelectorField({
    required String label,
    required String hint,
    required bool isSelected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          enabled: enabled,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hint,
              style: TextStyle(
                color: enabled
                    ? (isSelected ? Colors.black : Colors.black54)
                    : Colors.grey,
                fontSize: 16,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: enabled ? Colors.grey[700] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}