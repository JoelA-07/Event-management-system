import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/bookings/services/booking_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/payments/screens/payment_summary_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  Future<List<dynamic>> _loadBookings() async {
    const storage = FlutterSecureStorage();
    final id = await storage.read(key: "userId");
    final role = await storage.read(key: "role");
    if (id == null || role == null) return [];
    return BookingService().fetchUserBookings(int.parse(id), role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Event History", style: TextStyle(fontWeight: FontWeight.bold))),
      body: FutureBuilder<List<dynamic>>(
        future: _loadBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No bookings found yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final hall = booking['Hall'];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration, color: AppTheme.primaryColor),
                  ),
                  title: Text(hall['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("Date: ${booking['bookingDate']}"),
                      Text(
                        "Status: ${booking['status'].toUpperCase()}",
                        style: TextStyle(
                          color: booking['status'] == 'confirmed' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentSummaryScreen(
                              bookingType: 'hall',
                              bookingId: int.parse(booking['id'].toString()),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Payments'),
                      ),
                    ],
                  ),
                  trailing: Text(
                    "Rs ${hall['pricePerDay']}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
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
