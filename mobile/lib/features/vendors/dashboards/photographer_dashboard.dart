import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/vendors/services/vendor_stats_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/dashboard_header.dart';
import 'package:mobile/features/vendors/screens/vendor_photography_screen.dart';
import 'package:mobile/features/bookings/screens/vendor_bookings_screen.dart';
import 'package:mobile/features/vendors/screens/vendor_availability_screen.dart';

class PhotographerDashboard extends StatefulWidget {
  const PhotographerDashboard({super.key});

  @override
  State<PhotographerDashboard> createState() => _PhotographerDashboardState();
}

class _PhotographerDashboardState extends State<PhotographerDashboard> {
  Map<String, dynamic> _stats = {
    "totalEarnings": 0,
    "activeServices": 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
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
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const DashboardHeader(subTitle: "PHOTOGRAPHY STUDIO PANEL"),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Business Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _isLoading ? const Center(child: CircularProgressIndicator()) : _buildStatsGrid(),
                    const SizedBox(height: 30),
                    const Text("Studio Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Manage Portfolio",
                      "Upload new shoots and update prices",
                      Icons.camera_roll_outlined,
                      AppTheme.primaryColor,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotographyManagementScreen())),
                    ),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Manage Availability",
                      "Block dates and time slots",
                      Icons.lock_clock,
                      Colors.deepPurple,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorAvailabilityScreen())),
                    ),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Shoot Schedule",
                      "View your upcoming event dates",
                      Icons.calendar_month_outlined,
                      Colors.blue,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorBookingsScreen())),
                    ),
                    const SizedBox(height: 30),
                    _buildTipCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        _statItem("Active Services", _stats['activeServices'].toString(), Colors.purple),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.white, size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "Keep your recent albums updated to improve booking conversion.",
              style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

