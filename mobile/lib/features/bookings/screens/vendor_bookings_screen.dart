import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/vendors/services/vendor_booking_service.dart';
import 'package:mobile/core/theme.dart';

class VendorBookingsScreen extends StatelessWidget {
  const VendorBookingsScreen({super.key});

  Future<List<dynamic>> _loadBookings() async {
    const storage = FlutterSecureStorage();
    final vendorId = await storage.read(key: "userId");
    if (vendorId == null) return [];
    return VendorBookingService().fetchVendorBookings(int.parse(vendorId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Bookings")),
      body: FutureBuilder<List<dynamic>>(
        future: _loadBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }
          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.event_available)),
                  title: Text("Date: ${booking['bookingDate']}"),
                  subtitle: Text(booking['notes'] ?? "No notes"),
                  trailing: Chip(
                    label: Text((booking['status'] ?? 'pending').toString().toUpperCase()),
                    backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
