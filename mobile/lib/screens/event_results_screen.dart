import 'package:flutter/material.dart';
import '../utils/theme.dart';

class EventResultsScreen extends StatelessWidget {
  final String title;
  const EventResultsScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$title Services")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text("Best $title Packages", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          // Displaying "Packages" (Added by Organizers)
          _buildResultCard("Elite $title Bundle", "Hall + Food + Photo", "₹1,20,000", Icons.card_giftcard),
          const SizedBox(height: 15),
          
          Text("Individual $title Items", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          // Individual Items
          _buildResultCard("$title Special Hall", "Capacity: 300", "₹45,000", Icons.business),
          _buildResultCard("$title Catering Menu", "Starters + Main Course", "₹450/Plate", Icons.restaurant),
        ],
      ),
    );
  }

  Widget _buildResultCard(String name, String sub, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: Icon(icon, color: AppTheme.primaryColor)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}