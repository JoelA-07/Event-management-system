import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/vendor_service.dart';

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
  bool _isSaving = false;

  Future<void> _submitMenu() async {
    const storage = FlutterSecureStorage();
    final vId = await storage.read(key: "userId");
    if (!mounted) return;
    if (vId == null) return;

    if (_nameController.text.trim().isEmpty ||
        _itemsController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final samplePrice = _samplePriceController.text.trim().isEmpty
          ? 0
          : double.parse(_samplePriceController.text.trim());

      final res = await VendorService().addMenu({
        "vendorId": int.parse(vId),
        "packageName": _nameController.text.trim(),
        "menuItems": _itemsController.text.trim(),
        "pricePerPlate": double.parse(_priceController.text.trim()),
        "samplePrice": samplePrice,
        "isSampleAvailable": _isSampleAvailable,
      });

      if (!mounted) return;
      if (res?.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Menu saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?.data['message'] ?? "Failed to save menu")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save menu")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Package Name (e.g. Royal Buffet)",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _itemsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "List Items (comma separated)",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price Per Plate (Rs)"),
            ),
            const SizedBox(height: 15),
            SwitchListTile(
              title: const Text("Offer Sample Tasting?"),
              value: _isSampleAvailable,
              onChanged: (val) => setState(() => _isSampleAvailable = val),
            ),
            if (_isSampleAvailable)
              TextField(
                controller: _samplePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Sample Tasting Fee (Rs)",
                ),
              ),
            const SizedBox(height: 30),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitMenu,
                    child: const Text("SAVE MENU"),
                  ),
          ],
        ),
      ),
    );
  }
}
