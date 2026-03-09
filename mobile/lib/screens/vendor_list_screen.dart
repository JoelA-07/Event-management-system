import 'package:flutter/material.dart';
import '../models/vendor_model.dart';
import '../services/vendor_service.dart';
import '../utils/theme.dart';

class VendorListScreen extends StatelessWidget {
  final String category;
  const VendorListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final title = "${category[0].toUpperCase()}${category.substring(1)}";
    return Scaffold(
      appBar: AppBar(title: Text("$title Services")),
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
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: vendors.length,
            itemBuilder: (context, index) => _buildVendorCard(vendors[index]),
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(VendorModel vendor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10243C).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                vendor.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blueGrey.shade50,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Starting at Rs ${vendor.price.toStringAsFixed(0)}",
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
