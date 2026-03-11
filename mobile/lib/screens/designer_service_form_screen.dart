import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/vendor_model.dart';
import '../services/vendor_service.dart';
import '../utils/theme.dart';

class DesignerServiceFormScreen extends StatefulWidget {
  final VendorModel? existing;
  const DesignerServiceFormScreen({super.key, this.existing});

  @override
  State<DesignerServiceFormScreen> createState() => _DesignerServiceFormScreenState();
}

class _DesignerServiceFormScreenState extends State<DesignerServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _priceController.text = widget.existing!.price.toStringAsFixed(0);
      _descController.text = widget.existing!.description;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    const storage = FlutterSecureStorage();
    final vendorId = await storage.read(key: "userId");
    if (!mounted) return;
    if (vendorId == null) {
      setState(() => _isSaving = false);
      return;
    }

    final data = FormData.fromMap({
      "vendorId": int.parse(vendorId),
      "name": _nameController.text.trim(),
      "category": "designer",
      "price": double.parse(_priceController.text.trim()),
      "description": _descController.text.trim(),
      if (_selectedImage != null)
        "image": await MultipartFile.fromFile(_selectedImage!.path, filename: "design_${DateTime.now().millisecondsSinceEpoch}.jpg"),
    });

    final service = VendorService();
    final res = widget.existing == null
        ? await service.addServiceWithImage(data)
        : await service.updateServiceWithImage(widget.existing!.id, data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res?.statusCode == 201 || res?.statusCode == 200) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existing == null ? "Design created" : "Design updated")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to save design")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? "New Invitation Design" : "Edit Invitation Design")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
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
                            Text("Upload design image"),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Design Name"),
                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price per copy (Rs)"),
                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _save,
                      child: Text(widget.existing == null ? "CREATE DESIGN" : "SAVE CHANGES"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
