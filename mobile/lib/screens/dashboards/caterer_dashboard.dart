import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/dashboard_header.dart';
import '../vendor_caterer_screen.dart'; // Screen to manage menus
import '../my_booking_screen.dart';    // Screen to see event schedule
import '../caterer_add_menu_screen.dart'; // Screen to add new menu items

class CatererDashboard extends StatelessWidget {
  const CatererDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER (Reusable with Role Title)
            const DashboardHeader(subTitle: "CATERING & KITCHEN PANEL"),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. KITCHEN STATS SECTION
                  const Text(
                    "Kitchen Overview",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildStatsGrid(),

                  const SizedBox(height: 30),

                  // 3. MAIN ACTIONS SECTION
                  const Text(
                    "Menu & Order Management",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  
                  // Manage Menus Action
                  _buildActionCard(
                    context,
                    "Manage My Menus",
                    "Update plate prices and food items",
                    Icons.restaurant_menu_outlined,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CatererManagementScreen()),
                    ),
                  ),
                  
                  const SizedBox(height: 15),

                  // Sample Tasting Orders Action
                  _buildActionCard(
                    context,
                    "Sample Tasting Requests",
                    "View and manage food sample orders",
                    Icons.shopping_bag_outlined,
                    Colors.deepOrange,
                    () {
                      // Navigate to a screen that shows GET /api/vendors/order-sample results
                    },
                  ),

                  const SizedBox(height: 15),

                  // Event Schedule Action
                  _buildActionCard(
                    context,
                    "Event Schedule",
                    "Check dates for bulk catering orders",
                    Icons.calendar_month_outlined,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. HYGIENE & QUALITY TIP
                  _buildHygieneTip(),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button to quickly add a new menu
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCateringMenuScreen()),
        ),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Menu", style: TextStyle(color: Colors.white)),
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
        _statItem("Total Earnings", "₹2.4L", Colors.green),
        _statItem("Plates Served", "1.5k", Colors.orange),
        _statItem("Active Menus", "5", Colors.blue),
        _statItem("Sample Requests", "12", Colors.deepOrange),
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

  // --- HYGIENE TIP WIDGET ---
  Widget _buildHygieneTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.orange, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Pro-Tip: Ensure your FSSAI certificate is displayed on your profile to build client trust!",
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}