import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/vendor_model.dart';
import '../services/vendor_service.dart';
import '../utils/theme.dart';

class PhotographyManagementScreen extends StatefulWidget {
  const PhotographyManagementScreen({super.key});

  @override
  State<PhotographyManagementScreen> createState() => _PhotographyManagementScreenState();
}

class _PhotographyManagementScreenState extends State<PhotographyManagementScreen> {
  final VendorService _service = VendorService();
  List<VendorModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    const storage = FlutterSecureStorage();
    final vendorId = await storage.read(key: "userId");
    if (vendorId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final services = await _service.fetchMyServices(vendorId);
    if (!mounted) return;
    setState(() {
      _services = services.where((s) => s.category == 'photographer').toList();
      _isLoading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Photography Service"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Service Name"),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Starting Price"),
                ),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
          ],
        );
      },
    );

    if (shouldSave != true) return;

    const storage = FlutterSecureStorage();
    final vendorId = await storage.read(key: "userId");
    if (vendorId == null) return;

    final res = await _service.addService({
      "vendorId": int.parse(vendorId),
      "name": nameController.text.trim(),
      "category": "photographer",
      "price": double.tryParse(priceController.text.trim()) ?? 0,
      "description": descController.text.trim(),
      "imageUrl": "https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=600",
    });

    if (!mounted) return;
    if (res?.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service added"), backgroundColor: Colors.green),
      );
      _loadServices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to add service")),
      );
    }
  }

  Future<void> _deleteService(int id) async {
    final res = await _service.deleteService(id);
    if (!mounted) return;
    if (res?.statusCode == 200) {
      _loadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service removed"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to remove service")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Photography Studio")),
      body: RefreshIndicator(
        onRefresh: _loadServices,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _services.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 140),
                      Center(child: Text("No photography services yet")),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final item = _services[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.description),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Rs ${item.price.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteService(item.id),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text("Add Service", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
