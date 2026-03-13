import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/features/vendors/services/vendor_service.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/theme.dart';

class MehendiServiceFormScreen extends StatefulWidget {
  final VendorModel? existing;
  const MehendiServiceFormScreen({super.key, this.existing});

  @override
  State<MehendiServiceFormScreen> createState() => _MehendiServiceFormScreenState();
}

class _MehendiServiceFormScreenState extends State<MehendiServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;
  final List<File> _gallery = [];
  final List<String> _existingPortfolio = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _priceController.text = widget.existing!.price.toStringAsFixed(0);
      _descController.text = widget.existing!.description;
      _existingPortfolio.addAll(widget.existing!.portfolio);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _pickGallery() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      final available = AppConstants.maxPortfolioImages - _existingPortfolio.length - _gallery.length;
      if (available <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Portfolio limit reached")),
        );
        return;
      }
      final toAdd = images.take(available).map((e) => File(e.path)).toList();
      setState(() => _gallery.addAll(toAdd));
    }
  }

  Future<void> _removeExistingImage(String url) async {
    final res = await VendorService().deleteServiceImage(widget.existing!.id, url);
    if (!mounted) return;
    if (res?.statusCode == 200) {
      setState(() => _existingPortfolio.remove(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to remove image")),
      );
    }
  }

  void _removePickedImage(int index) {
    setState(() => _gallery.removeAt(index));
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
      "category": "mehendi",
      "price": double.parse(_priceController.text.trim()),
      "description": _descController.text.trim(),
      if (_selectedImage != null)
        "image": await MultipartFile.fromFile(_selectedImage!.path, filename: "mehendi_${DateTime.now().millisecondsSinceEpoch}.jpg"),
    });

    final service = VendorService();
    final res = widget.existing == null
        ? await service.addServiceWithImage(data)
        : await service.updateServiceWithImage(widget.existing!.id, data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res?.statusCode == 201 || res?.statusCode == 200) {
      final serviceId = widget.existing?.id ?? res?.data['id'];
      if (serviceId != null && _gallery.isNotEmpty) {
        await service.uploadServiceImages(
          serviceId,
          _gallery.map((f) => f.path).toList(),
        );
      }
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
      appBar: AppBar(title: Text(widget.existing == null ? "New Mehendi Design" : "Edit Mehendi Design")),
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
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickGallery,
                    icon: const Icon(Icons.collections),
                    label: Text("Add Portfolio Images (${_existingPortfolio.length + _gallery.length}/${AppConstants.maxPortfolioImages})"),
                  ),
                ],
              ),
              if (_existingPortfolio.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildExistingGallery(),
              ],
              if (_gallery.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPickedGallery(),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Design Name"),
                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Starting Price (Rs)"),
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

  Widget _buildExistingGallery() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _existingPortfolio.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = _absoluteUrl(_existingPortfolio[index]);
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(url, width: 110, height: 90, fit: BoxFit.cover),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => _removeExistingImage(_existingPortfolio[index]),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPickedGallery() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _gallery.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = _gallery[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(file, width: 110, height: 90, fit: BoxFit.cover),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => _removePickedImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _absoluteUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final base = AppConstants.baseUrl.replaceAll('/api', '');
    return "$base$raw";
  }
}
