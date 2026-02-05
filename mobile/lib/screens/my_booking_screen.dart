import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/booking_service.dart';
import '../utils/theme.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  Future<List<dynamic>> _loadBookings() async {
    const storage = FlutterSecureStorage();
    String? id = await storage.read(key: "userId");
    String? role = await storage.read(key: "role");
    
    return await BookingService().fetchUserBookings(int.parse(id!), role!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Event History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
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
            padding: const EdgeInsets.all(15),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final hall = booking['Hall']; // Accessing the joined data

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.celebration, color: AppTheme.primaryColor),
                  ),
                  title: Text(hall['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("Date: ${booking['bookingDate']}", style: const TextStyle(color: Colors.black87)),
                      Text("Status: ${booking['status'].toUpperCase()}", 
                           style: TextStyle(color: booking['status'] == 'confirmed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: Text("₹${hall['pricePerDay']}", 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}