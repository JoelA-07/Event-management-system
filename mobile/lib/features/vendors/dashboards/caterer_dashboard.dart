import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/vendors/services/vendor_stats_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/dashboard_header.dart';
import 'package:mobile/features/vendors/screens/caterer_add_menu_screen.dart';
import 'package:mobile/features/vendors/screens/caterer_sample_orders_screen.dart';
import 'package:mobile/features/bookings/screens/vendor_bookings_screen.dart';
import 'package:mobile/features/vendors/screens/vendor_caterer_screen.dart';
import 'package:mobile/features/vendors/screens/caterer_services_screen.dart';

class CatererDashboard extends StatefulWidget {
  const CatererDashboard({super.key});

  @override
  State<CatererDashboard> createState() => _CatererDashboardState();
}

class _CatererDashboardState extends State<CatererDashboard> {
  Map<String, dynamic> _stats = {
    "totalEarnings": 0,
    "activeServices": 0,
    "activeMenus": 0,
    "sampleRequests": 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealStats();
  }

  Future<void> _loadRealStats() async {
    const storage = FlutterSecureStorage();
    final vendorId = await storage.read(key: "userId");
    if (vendorId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final stats = await VendorStatsService().fetchStats(vendorId);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        onRefresh: _loadRealStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const DashboardHeader(subTitle: "CATERING & KITCHEN PANEL"),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Kitchen Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _isLoading ? const Center(child: CircularProgressIndicator()) : _buildStatsGrid(),
                    const SizedBox(height: 30),
                    const Text("Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Manage Catering Services",
                      "Packages used for bookings",
                      Icons.room_service,
                      Colors.indigo,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatererServicesScreen())),
                    ),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Manage My Menus",
                      "Edit prices, items, images",
                      Icons.restaurant_menu,
                      Colors.orange,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatererManagementScreen())),
                    ),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Sample Tasting Requests",
                      "Manage food sample orders",
                      Icons.shopping_bag,
                      Colors.deepOrange,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatererSampleOrdersScreen())),
                    ),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Event Schedule",
                      "Bulk catering dates",
                      Icons.calendar_month,
                      Colors.green,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorBookingsScreen())),
                    ),
                    const SizedBox(height: 30),
                    _buildHygieneTip(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCateringMenuScreen())),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Menu", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _statItem("Total Earnings", "Rs ${_stats['totalEarnings']}", Colors.green),
        _statItem("Active Services", _stats['activeServices'].toString(), Colors.orange),
        _statItem("Active Menus", _stats['activeMenus'].toString(), Colors.blue),
        _statItem("Pending Samples", _stats['sampleRequests'].toString(), Colors.deepOrange),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHygieneTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user, color: Colors.orange),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "Ensure your FSSAI certificate is displayed on your profile!",
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

