import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/theme.dart';
import '../services/package_service.dart';

class PackageBuilderScreen extends StatefulWidget {
  const PackageBuilderScreen({super.key});

  @override
  State<PackageBuilderScreen> createState() => _PackageBuilderScreenState();
}

class _PackageBuilderScreenState extends State<PackageBuilderScreen> {
  final PackageService _service = PackageService();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  List<dynamic> _halls = [];
  List<dynamic> _vendorServices = [];
  final List<int> _selectedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    final data = await _service.fetchAllSelectables();
    setState(() {
      _halls = data['halls']!;
      _vendorServices = data['vendors']!;
      _isLoading = false;
    });
  }

  void _submitPackage() async {
    if (_titleController.text.isEmpty || _selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a title and select services")));
      return;
    }

    const storage = FlutterSecureStorage();
    String? orgId = await storage.read(key: "userId");

    final packageData = {
      "organizerId": int.parse(orgId!),
      "title": _titleController.text,
      "description": _descController.text,
      "totalPrice": double.parse(_priceController.text),
      "serviceIds": _selectedIds, // This goes to the JSON column in your MySQL
    };

    final res = await _service.createPackage(packageData);
    if (res?.statusCode == 201) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Combo Package Created!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Build Combo Package")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              // 1. INPUT FIELDS
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Package Title")),
                    const SizedBox(height: 10),
                    TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Discounted Combo Price (₹)"), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              
              const Divider(),
              const Text("Select Components", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),

              // 2. SCROLLABLE LIST OF EVERYTHING
              Expanded(
                child: ListView(
                  children: [
                    const Padding(padding: EdgeInsets.all(10), child: Text("VENUES", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    ..._halls.map((h) => _selectionTile(h['id'], h['name'], "Venue", h['pricePerDay'].toString())),
                    
                    const Padding(padding: EdgeInsets.all(10), child: Text("VENDOR SERVICES", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    ..._vendorServices.map((v) => _selectionTile(v['id'], v['name'], v['category'], v['price'].toString())),
                  ],
                ),
              ),

              // 3. SUBMIT BUTTON
              Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _submitPackage,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
                  child: const Text("FINALIZE & PUBLISH PACKAGE"),
                ),
              )
            ],
          ),
    );
  }

  Widget _selectionTile(int id, String name, String sub, String price) {
    bool isSelected = _selectedIds.contains(id);
    return CheckboxListTile(
      value: isSelected,
      activeColor: AppTheme.primaryColor,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub.toUpperCase()),
      secondary: Text("₹$price", style: const TextStyle(fontWeight: FontWeight.bold)),
      onChanged: (val) {
        setState(() {
          val! ? _selectedIds.add(id) : _selectedIds.remove(id);
        });
      },
    );
  }
}