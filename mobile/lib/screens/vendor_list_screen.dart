import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../models/vendor_model.dart';
import '../utils/theme.dart';

class VendorListScreen extends StatelessWidget {
  final String category; // 'photographer', 'caterer', etc.
  const VendorListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Top ${category[0].toUpperCase()}${category.substring(1)}s"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<VendorModel>>(
        future: VendorService().fetchServices(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No vendors available in this category."));
          }

          final vendors = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return _buildVendorCard(context, vendor);
            },
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorModel vendor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(vendor.imageUrl, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Starting at ₹${vendor.price}", 
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}