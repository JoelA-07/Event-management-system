import 'package:flutter/material.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/dashboard_header.dart';
import 'package:mobile/features/organizer/screens/organizer_package_builder.dart';
import 'package:mobile/features/halls/screens/hall_list_screen.dart';
import 'package:mobile/features/organizer/dashboards/organizer_decorator_dashboard.dart';
import 'package:mobile/features/organizer/services/organizer_service.dart';

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait([
          OrganizerService().fetchOverview(),
          OrganizerService().fetchAnalytics(),
        ]),
        builder: (context, snapshot) {
          final overview = snapshot.data?.isNotEmpty == true ? snapshot.data![0] : {};
          final analytics = snapshot.data?.length == 2 ? snapshot.data![1] : {};

          final totals = Map<String, dynamic>.from(overview['totals'] ?? {});
          final hallBookings = List<dynamic>.from(overview['recentHallBookings'] ?? []);
          final vendorBookings = List<dynamic>.from(overview['recentVendorBookings'] ?? []);
          final revenueTotals = Map<String, dynamic>.from(analytics['totals'] ?? {});
          final monthly = List<dynamic>.from(analytics['monthly'] ?? []);

          return SingleChildScrollView(
            child: Column(
              children: [
                const DashboardHeader(subTitle: "ORGANIZER COMMAND CENTER"),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Revenue Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildRevenueHero(revenueTotals),
                      const SizedBox(height: 18),
                      _buildMonthlyStrip(monthly),
                      const SizedBox(height: 25),
                      const Text("Platform Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildStatsRow(totals),
                      const SizedBox(height: 25),
                      const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildTile(context, "Build Package", "Combo Hall + Photo + Food", Icons.auto_awesome_motion, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageBuilderScreen()))),
                      _buildTile(context, "Manage Halls", "Add or Edit venues", Icons.business, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HallListScreen()))),
                      _buildTile(context, "Decorator Studio", "Manage decoration packages", Icons.brush, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerDecoratorDashboard()))),
                      const SizedBox(height: 25),
                      const Text("Recent Hall Bookings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildBookingList(hallBookings, isVendor: false),
                      const SizedBox(height: 20),
                      const Text("Recent Vendor Bookings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildBookingList(vendorBookings, isVendor: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(context, title, sub, icon, onTap) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(onTap: onTap, leading: Icon(icon, color: AppTheme.primaryColor), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right)),
  );

  Widget _buildStatsRow(Map<String, dynamic> totals) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard("Hall Bookings", totals['totalHallBookings']?.toString() ?? "0", Icons.fort, Colors.indigo),
        _statCard("Vendor Bookings", totals['totalVendorBookings']?.toString() ?? "0", Icons.store, Colors.green),
        _statCard("Active Vendors", totals['totalVendors']?.toString() ?? "0", Icons.people, Colors.orange),
        _statCard("Total Users", totals['totalUsers']?.toString() ?? "0", Icons.person, Colors.blueGrey),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<dynamic> items, {required bool isVendor}) {
    if (items.isEmpty) {
      return const Text("No recent bookings yet.", style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: items.map((item) {
        final title = isVendor
            ? (item['VendorService']?['name'] ?? 'Vendor Service')
            : (item['Hall']?['name'] ?? 'Hall Booking');
        final subtitle = isVendor
            ? (item['VendorService']?['category'] ?? 'vendor')
            : "Date: ${item['bookingDate']}";
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(isVendor ? Icons.store : Icons.fort, color: AppTheme.primaryColor),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
            trailing: Text(
              isVendor
                  ? "Rs ${item['VendorService']?['price'] ?? '-'}"
                  : "Rs ${item['Hall']?['pricePerDay'] ?? '-'}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevenueHero(Map<String, dynamic> revenue) {
    final total = revenue['totalRevenue']?.toString() ?? "0";
    final hall = revenue['hallRevenue']?.toString() ?? "0";
    final vendor = revenue['vendorRevenue']?.toString() ?? "0";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text("Rs $total", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniPill("Halls", "Rs $hall"),
              const SizedBox(width: 10),
              _miniPill("Vendors", "Rs $vendor"),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMonthlyStrip(List<dynamic> monthly) {
    if (monthly.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: monthly.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = monthly[index];
          final total = item['totalRevenue'] ?? 0;
          return Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Month ${item['month']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Rs $total", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}
