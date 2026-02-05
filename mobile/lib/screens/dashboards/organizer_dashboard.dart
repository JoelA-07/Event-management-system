import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/dashboard_header.dart';
import '../my_booking_screen.dart';
import '../organizer_package_builder.dart';
import '../hall_list_screen.dart';

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        child: Column(children: [
          const DashboardHeader(subTitle: "ADMIN CONTROL PANEL"),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _buildTile(context, "View Bookings", "Monitor all events", Icons.analytics, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),
              _buildTile(context, "Build Package", "Combo Hall + Photo + Food", Icons.auto_awesome_motion, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageBuilderScreen()))),
              _buildTile(context, "Manage Halls", "Add or Edit venues", Icons.business, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HallListScreen()))),
            ]),
          )
        ]),
      ),
    );
  }

  Widget _buildTile(context, title, sub, icon, onTap) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(onTap: onTap, leading: Icon(icon, color: AppTheme.primaryColor), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right)),
  );
}