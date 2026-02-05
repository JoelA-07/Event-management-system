import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/dashboard_header.dart';
import '../add_hall_screen.dart';
import '../my_booking_screen.dart';

class HallOwnerDashboard extends StatelessWidget {
  const HallOwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Reusable header specifically for the Venue Owner
            const DashboardHeader(subTitle: "VENUE OWNER PANEL"),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Property Management",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // 1. ADD NEW HALL CARD
                  _buildActionCard(
                    context,
                    "Add New Venue",
                    "List your property for upcoming events",
                    Icons.add_business,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddHallScreen()),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 2. VIEW BOOKINGS CARD
                  _buildActionCard(
                    context,
                    "My Venue Bookings",
                    "Check dates and client details",
                    Icons.history,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. PERFORMANCE STATS (Visual only for now)
                  const Text(
                    "Monthly Overview",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildMiniStat("Total Earnings", "₹45k", Colors.green),
                      const SizedBox(width: 15),
                      _buildMiniStat("Active Slots", "8", Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for consistent Action Cards
  Widget _buildActionCard(BuildContext context, String title, String sub, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  // Helper for small Stat boxes
  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
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