import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart'; // Required for picking images
import 'package:dio/dio.dart'; // Required for FormData
import 'package:mobile/features/halls/providers/hall_provider.dart';
import 'package:mobile/core/theme.dart';

class AddHallScreen extends StatefulWidget {
  const AddHallScreen({super.key});

  @override
  State<AddHallScreen> createState() => _AddHallScreenState();
}

class _AddHallScreenState extends State<AddHallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  // IMAGE PICKER LOGIC
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress slightly for faster upload
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submit() async {
    // 1. Basic Validation
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image for the hall")),
      );
      return;
    }

    const storage = FlutterSecureStorage();
    String? userIdStr = await storage.read(key: "userId");
    int currentUserId = int.parse(userIdStr ?? "1"); 

    final hallProvider = context.read<HallProvider>();

    // 2. Prepare FormData (Crucial for Multer/File Upload)
    FormData formData = FormData.fromMap({
      "name": _nameController.text,
      "location": _locationController.text,
      "capacity": int.parse(_capacityController.text),
      "pricePerDay": double.parse(_priceController.text),
      "description": _descController.text,
      "ownerId": currentUserId,
      // The key 'image' must match the backend upload.single('image')
      "image": await MultipartFile.fromFile(
        _selectedImage!.path,
        filename: "hall_upload.jpg",
      ),
    });

    // 3. Call Provider (Now passing FormData instead of a Map)
    String? error = await hallProvider.addHall(formData);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hall Added Successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Venue"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE SELECTION BOX
              const Text("Venue Photo", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: AppTheme.primaryColor),
                            SizedBox(height: 10),
                            Text("Tap to upload hall photo", style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 25),

              // FORM FIELDS
              _buildField(_nameController, "Hall Name", Icons.business),
              _buildField(_locationController, "Location (City, Area)", Icons.location_on),
              _buildField(_capacityController, "Guest Capacity", Icons.people, isNumber: true),
              _buildField(_priceController, "Price Per Day (₹)", Icons.currency_rupee, isNumber: true),
              _buildField(_descController, "Description", Icons.description, maxLines: 3),
              
              const SizedBox(height: 30),
              
              // SUBMIT BUTTON
              context.watch<HallProvider>().isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      child: const Text("CREATE HALL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value!.isEmpty ? "Required" : null,
      ),
    );
  }
}
