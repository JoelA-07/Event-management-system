import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/vendor_service.dart';
import '../utils/theme.dart';

class AddCateringMenuScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const AddCateringMenuScreen({super.key, this.existing});

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
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!['packageName'] ?? '';
      _itemsController.text = widget.existing!['menuItems'] ?? '';
      _priceController.text = widget.existing!['pricePerPlate']?.toString() ?? '';
      _samplePriceController.text = widget.existing!['samplePrice']?.toString() ?? '';
      _isSampleAvailable = widget.existing!['isSampleAvailable'] ?? true;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

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

      final data = FormData.fromMap({
        "vendorId": int.parse(vId),
        "packageName": _nameController.text.trim(),
        "menuItems": _itemsController.text.trim(),
        "pricePerPlate": double.parse(_priceController.text.trim()),
        "samplePrice": samplePrice,
        "isSampleAvailable": _isSampleAvailable,
        if (_selectedImage != null)
          "image": await MultipartFile.fromFile(_selectedImage!.path, filename: "menu_${DateTime.now().millisecondsSinceEpoch}.jpg"),
      });

      final res = widget.existing == null
          ? await VendorService().addMenuWithImage(data)
          : await VendorService().updateMenuWithImage(widget.existing!['id'] as int, data);

      if (!mounted) return;
      if (res?.statusCode == 201 || res?.statusCode == 200) {
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
      appBar: AppBar(title: Text(widget.existing == null ? "Create Catering Package" : "Edit Catering Package")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: AppTheme.primaryColor),
                          SizedBox(height: 8),
                          Text("Upload menu image"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
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
                    child: Text(widget.existing == null ? "SAVE MENU" : "SAVE CHANGES"),
                  ),
          ],
        ),
      ),
    );
  }
}
