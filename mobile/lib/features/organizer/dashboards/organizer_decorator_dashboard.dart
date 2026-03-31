import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/vendors/services/vendor_service.dart';
import 'package:mobile/features/vendors/services/vendor_booking_service.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/dashboard_header.dart';
import 'package:mobile/features/vendors/screens/decorator_service_form_screen.dart';
import 'package:mobile/features/vendors/screens/vendor_availability_screen.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorAvailabilityScreen()),
                    ),
                    icon: const Icon(Icons.lock_clock),
                    label: const Text("Manage Availability"),
                  ),
                ),
              ],
            ),
          ),
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
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              trailing: SizedBox(
                width: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Rs ${item.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
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
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                          onPressed: () => _deleteService(item.id),
                        ),
                      ],
                    ),
                  ],
                ),
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


