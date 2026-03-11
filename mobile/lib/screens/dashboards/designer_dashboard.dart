import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/dashboard_header.dart';
import '../designer_services_screen.dart';
import '../vendor_bookings_screen.dart';

class DesignerDashboard extends StatelessWidget {
  const DesignerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DashboardHeader(subTitle: "INVITATION DESIGN STUDIO"),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Design Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildActionCard(
                    context,
                    "Manage Designs",
                    "Upload new templates and pricing",
                    Icons.design_services,
                    AppTheme.primaryColor,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignerServicesScreen())),
                  ),
                  const SizedBox(height: 15),
                  _buildActionCard(
                    context,
                    "Order Requests",
                    "View upcoming design bookings",
                    Icons.calendar_month_outlined,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorBookingsScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
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
}
