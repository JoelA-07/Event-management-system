import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/theme.dart';
import '../screens/my_booking_screen.dart'; // 1. Import the bookings screen
import '../main.dart'; // To navigate back to login on logout

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Function to handle Logout
  void _handleLogout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll(); // Clears user data
    
    if (context.mounted) {
      // Navigates to the route named '/login' and clears all history
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50, 
              backgroundColor: AppTheme.primaryColor, 
              child: Icon(Icons.person, size: 50, color: Colors.white)
            ),
          ),
          const SizedBox(height: 30),
          
          // Edit Profile
          _buildProfileOption(Icons.person_outline, "Edit Profile", () {}),
          
          // 2. THIS IS THE FIX: Link My Bookings
          _buildProfileOption(Icons.history, "My Bookings", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
            );
          }),
          
          _buildProfileOption(Icons.notifications_outlined, "Notifications", () {}),
          _buildProfileOption(Icons.security, "Privacy & Security", () {}),
          
          const Divider(height: 40),
          
          // Logout Option
          _buildProfileOption(
            Icons.logout, 
            "Logout", 
            () => _handleLogout(context), 
            isDestructive: true
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryColor),
      title: Text(
        title, 
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500
        )
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}