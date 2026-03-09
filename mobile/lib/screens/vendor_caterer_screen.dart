import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/vendor_service.dart';
import '../utils/theme.dart';
import 'caterer_add_menu_screen.dart';

class CatererManagementScreen extends StatefulWidget {
  const CatererManagementScreen({super.key});

  @override
  State<CatererManagementScreen> createState() => _CatererManagementScreenState();
}

class _CatererManagementScreenState extends State<CatererManagementScreen> {
  final VendorService _service = VendorService();
  List<dynamic> _menus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    const storage = FlutterSecureStorage();
    final vendorId = await storage.read(key: "userId");
    if (vendorId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final menus = await _service.fetchMyMenus(vendorId);
    if (!mounted) return;
    setState(() {
      _menus = menus;
      _isLoading = false;
    });
  }

  Future<void> _deleteMenu(int id) async {
    final res = await _service.deleteMenu(id);
    if (!mounted) return;
    if (res?.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menu deleted"), backgroundColor: Colors.green),
      );
      _loadMenus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to delete menu")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu Management")),
      body: RefreshIndicator(
        onRefresh: _loadMenus,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _menus.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 140),
                      Center(child: Text("No active menus yet")),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _menus.length,
                    itemBuilder: (context, index) {
                      final menu = _menus[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          title: Text(
                            menu['packageName'] ?? 'Menu Package',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(menu['menuItems'] ?? ''),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Rs ${menu['pricePerPlate']}",
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteMenu(menu['id'] as int),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: "Delete menu",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddCateringMenuScreen()),
          );
          if (created == true) _loadMenus();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Menu", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
