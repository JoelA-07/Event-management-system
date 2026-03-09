import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/vendor_stats_service.dart';
import '../../utils/theme.dart';
import '../../widgets/dashboard_header.dart';
import '../add_hall_screen.dart';
import '../my_booking_screen.dart';

class HallOwnerDashboard extends StatefulWidget {
  const HallOwnerDashboard({super.key});

  @override
  State<HallOwnerDashboard> createState() => _HallOwnerDashboardState();
}

class _HallOwnerDashboardState extends State<HallOwnerDashboard> {
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

    final data = await VendorStatsService().fetchStats(vendorId);
    if (!mounted) return;
    setState(() {
      _stats = data;
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
              const DashboardHeader(subTitle: "VENUE OWNER PANEL"),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Property Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "Add New Venue",
                      "List your property for upcoming events",
                      Icons.add_business,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddHallScreen())),
                    ),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      context,
                      "My Venue Bookings",
                      "Check dates and client details",
                      Icons.history,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                    ),
                    const SizedBox(height: 30),
                    const Text("Monthly Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
                        children: [
                          _buildMiniStat("Total Earnings", "Rs ${_stats['totalEarnings']}", Colors.green),
                          const SizedBox(width: 15),
                          _buildMiniStat("Active Listings", _stats['activeServices'].toString(), Colors.blue),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

