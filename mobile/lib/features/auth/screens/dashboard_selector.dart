import 'package:flutter/material.dart';
import 'package:mobile/features/organizer/dashboards/organizer_dashboard.dart';
import 'package:mobile/features/vendors/dashboards/customer_dashboard.dart';
import 'package:mobile/features/vendors/dashboards/hall_owner_dashboard.dart';
import 'package:mobile/features/vendors/dashboards/photographer_dashboard.dart'; // New
import 'package:mobile/features/vendors/dashboards/caterer_dashboard.dart'; // New
import 'package:mobile/features/vendors/dashboards/designer_dashboard.dart';
import 'package:mobile/features/vendors/dashboards/mehendi_dashboard.dart';

class DashboardSelector extends StatelessWidget {
  final String role;
  const DashboardSelector({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'organizer':
        return const OrganizerDashboard();
      case 'customer':
        return const CustomerDashboard();
      case 'hall_owner':
        return const HallOwnerDashboard();
      case 'photographer':
        return const PhotographerDashboard(); // Specific file
      case 'caterer':
        return const CatererDashboard(); // Specific file
      case 'designer':
        return const DesignerDashboard();
      case 'mehendi':
        return const MehendiDashboard();
      default:
        // Default fallback for other vendors (like card designers)
        return const Scaffold(body: Center(child: Text("Vendor Dashboard")));
    }
  }
}
