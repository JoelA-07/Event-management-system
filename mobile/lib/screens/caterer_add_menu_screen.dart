import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class AddCateringMenuScreen extends StatefulWidget {
  const AddCateringMenuScreen({super.key});

  @override
  State<AddCateringMenuScreen> createState() => _AddCateringMenuScreenState();
}

class _AddCateringMenuScreenState extends State<AddCateringMenuScreen> {
  final _nameController = TextEditingController();
  final _itemsController = TextEditingController();
  final _priceController = TextEditingController();
  final _samplePriceController = TextEditingController();
  bool _isSampleAvailable = true;

  void _submitMenu() async {
    const storage = FlutterSecureStorage();
    String? vId = await storage.read(key: "userId");

    try {
      await Dio().post("${AppConstants.baseUrl}/vendors/add-menu", data: {
        "vendorId": int.parse(vId!),
        "packageName": _nameController.text,
        "menuItems": _itemsController.text,
        "pricePerPlate": double.parse(_priceController.text),
        "samplePrice": double.parse(_samplePriceController.text),
        "isSampleAvailable": _isSampleAvailable,
      });
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Catering Package")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Package Name (e.g. Royal Buffet)")),
            const SizedBox(height: 15),
            TextField(controller: _itemsController, maxLines: 3, decoration: const InputDecoration(labelText: "List Items (comma separated)")),
            const SizedBox(height: 15),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price Per Plate (₹)")),
            const SizedBox(height: 15),
            SwitchListTile(
              title: const Text("Offer Sample Tasting?"),
              value: _isSampleAvailable, 
              onChanged: (val) => setState(() => _isSampleAvailable = val),
            ),
            if (_isSampleAvailable)
              TextField(controller: _samplePriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Sample Tasting Fee (₹)")),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _submitMenu, child: const Text("SAVE MENU")),
          ],
        ),
      ),
    );
  }
}