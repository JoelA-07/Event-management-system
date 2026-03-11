import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/vendor_model.dart';
import '../services/vendor_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'caterer_service_form_screen.dart';

class CatererServicesScreen extends StatefulWidget {
  const CatererServicesScreen({super.key});

  @override
  State<CatererServicesScreen> createState() => _CatererServicesScreenState();
}

class _CatererServicesScreenState extends State<CatererServicesScreen> {
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
      _services = services.where((s) => s.category == 'caterer').toList();
      _isLoading = false;
    });
  }

  Future<void> _openForm({VendorModel? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CatererServiceFormScreen(existing: existing)),
    );
    if (saved == true) _loadServices();
  }

  Future<void> _deleteService(int id) async {
    final res = await _service.deleteService(id);
    if (!mounted) return;
    if (res?.statusCode == 200) {
      _loadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service deleted"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to delete service")),
      );
    }
  }

  String _imageUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final base = AppConstants.baseUrl.replaceAll('/api', '');
    return "$base$raw";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Catering Services")),
      body: RefreshIndicator(
        onRefresh: _loadServices,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _services.isEmpty
                ? ListView(children: const [SizedBox(height: 120), Center(child: Text("No services yet"))])
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final item = _services[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrl(item.imageUrl),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _openForm(existing: item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteService(item.id),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Service", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
