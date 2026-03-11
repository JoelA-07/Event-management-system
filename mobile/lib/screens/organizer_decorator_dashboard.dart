import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/vendor_service.dart';
import '../services/vendor_booking_service.dart';
import '../models/vendor_model.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/dashboard_header.dart';
import 'decorator_service_form_screen.dart';

class OrganizerDecoratorDashboard extends StatefulWidget {
  const OrganizerDecoratorDashboard({super.key});

  @override
  State<OrganizerDecoratorDashboard> createState() => _OrganizerDecoratorDashboardState();
}

class _OrganizerDecoratorDashboardState extends State<OrganizerDecoratorDashboard>
    with SingleTickerProviderStateMixin {
  final VendorService _vendorService = VendorService();
  final VendorBookingService _bookingService = VendorBookingService();
  final _storage = const FlutterSecureStorage();

  List<VendorModel> _services = [];
  List<dynamic> _bookings = [];
  bool _loadingServices = true;
  bool _loadingBookings = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadServices();
    _loadBookings();
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    final vendorId = await _storage.read(key: "userId");
    if (vendorId == null) {
      setState(() => _loadingServices = false);
      return;
    }
    final services = await _vendorService.fetchMyServices(vendorId);
    if (!mounted) return;
    setState(() {
      _services = services.where((s) => s.category == 'decorator').toList();
      _loadingServices = false;
    });
  }

  Future<void> _loadBookings() async {
    setState(() => _loadingBookings = true);
    final vendorId = await _storage.read(key: "userId");
    if (vendorId == null) {
      setState(() => _loadingBookings = false);
      return;
    }
    final bookings = await _bookingService.fetchVendorBookings(int.parse(vendorId));
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _loadingBookings = false;
    });
  }

  Future<void> _deleteService(int id) async {
    final res = await _vendorService.deleteService(id);
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
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          const DashboardHeader(subTitle: "DECORATOR STUDIO"),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: "Services"),
                Tab(text: "Bookings"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildBookingsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const DecoratorServiceFormScreen()),
          );
          if (created == true) _loadServices();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Decor Package", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_services.isEmpty) {
      return const Center(child: Text("No decoration packages yet"));
    }
    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final item = _services[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageUrl(item.imageUrl ?? ''),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
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
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DecoratorServiceFormScreen(existing: item),
                            ),
                          );
                          if (updated == true) _loadServices();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteService(item.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsTab() {
    if (_loadingBookings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookings.isEmpty) {
      return const Center(child: Text("No bookings yet"));
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.event_available)),
              title: Text("Date: ${booking['bookingDate']}"),
              subtitle: Text(booking['notes'] ?? "No notes"),
              trailing: Chip(
                label: Text((booking['status'] ?? 'pending').toString().toUpperCase()),
              ),
            ),
          );
        },
      ),
    );
  }
}
