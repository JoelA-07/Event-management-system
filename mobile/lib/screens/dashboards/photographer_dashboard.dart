import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/dashboard_header.dart';
import '../vendor_photography_screen.dart'; // Screen to manage portfolio
import '../my_booking_screen.dart';       // Screen to see shoot dates

class PhotographerDashboard extends StatelessWidget {
  const PhotographerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER (Reusable with Role Title)
            const DashboardHeader(subTitle: "PHOTOGRAPHY STUDIO PANEL"),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. PERFORMANCE STATS SECTION
                  const Text(
                    "Business Overview",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildStatsGrid(),

                  const SizedBox(height: 30),

                  // 3. MAIN ACTIONS SECTION
                  const Text(
                    "Studio Management",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  
                  // Manage Portfolio Action
                  _buildActionCard(
                    context,
                    "Manage Portfolio",
                    "Upload new shoots and update prices",
                    Icons.camera_roll_outlined,
                    AppTheme.primaryColor,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PhotographyManagementScreen()),
                    ),
                  ),
                  
                  const SizedBox(height: 15),

                  // Shoot Schedule Action
                  _buildActionCard(
                    context,
                    "Shoot Schedule",
                    "View your upcoming event dates",
                    Icons.calendar_month_outlined,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. TIPS SECTION
                  _buildTipCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STATS GRID WIDGET ---
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _statItem("Total Revenue", "₹1.2L", Colors.green),
        _statItem("Shoots Done", "24", Colors.purple),
        _statItem("Pending", "3", Colors.orange),
        _statItem("Reviews", "4.8 ★", Colors.blue),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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

  // --- ACTION CARD WIDGET ---
  Widget _buildActionCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
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

  // --- TIP CARD WIDGET ---
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
              "Organizer Tip: High-quality thumbnails increase your booking chances by 40%!",
              style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}