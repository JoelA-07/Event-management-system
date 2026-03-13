import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/dashboard_header.dart';
import 'package:mobile/features/bookings/screens/my_booking_screen.dart';
import 'package:mobile/features/vendors/screens/vendor_photography_screen.dart';
import 'package:mobile/features/vendors/screens/vendor_caterer_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  String _role = "";
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadVendorRole();
  }

  // Detect if the vendor is a Photographer, Caterer, etc.
  _loadVendorRole() async {
    String? r = await _storage.read(key: "role");
    setState(() {
      _role = r ?? "Vendor";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Reusable header with dynamic role title
            DashboardHeader(subTitle: "${_role.toUpperCase()} SERVICE PORTAL"),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Business Management",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // 1. DYNAMIC CATALOG MANAGEMENT
                  _buildVendorAction(
                    context,
                    "Manage My Catalog",
                    "Update your portfolio, menus, and pricing",
                    Icons.edit_note,
                    () {
                      if (_role == 'photographer') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotographyManagementScreen()));
                      } else if (_role == 'caterer') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CatererManagementScreen()));
                      }
                      // You can add more roles like 'designer' here easily
                    },
                  ),

                  const SizedBox(height: 15),

                  // 2. WORK SCHEDULE / BOOKINGS
                  _buildVendorAction(
                    context,
                    "My Work Schedule",
                    "View upcoming bookings and client requirements",
                    Icons.calendar_month,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. VENDOR PERFORMANCE STATS
                  const Text(
                    "Service Stats",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatBox("Total Revenue", "₹32k", Colors.purple),
                      const SizedBox(width: 15),
                      _buildStatBox("New Requests", "3", Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 30),
                  
                  // HELPFUL TIP CARD
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppTheme.accentColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Tip: Keep your portfolio updated with your latest work to attract more customers.",
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorAction(BuildContext context, String title, String sub, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(bottom: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
