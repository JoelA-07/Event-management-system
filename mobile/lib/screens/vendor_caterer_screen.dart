import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CatererManagementScreen extends StatelessWidget {
  const CatererManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu Management")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Active Menu Packages", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildMenuCard("South Indian Buffet", "₹450/plate", "2 Starters, 5 Main, 2 Desserts"),
          _buildMenuCard("North Indian Deluxe", "₹650/plate", "Paneer Special, Dal Makhani, 3 Desserts"),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.restaurant_menu),
            label: const Text("Create New Menu"),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, String price, String items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(items),
        trailing: Text(price, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}