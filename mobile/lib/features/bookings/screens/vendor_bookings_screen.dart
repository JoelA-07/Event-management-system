import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/vendors/services/vendor_booking_service.dart';
import 'package:mobile/core/theme.dart';

class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  final VendorBookingService _service = VendorBookingService();
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    const storage = FlutterSecureStorage();
    final vendorId = await storage.read(key: "userId");
    if (vendorId == null) {
      setState(() {
        _loading = false;
        _bookings = [];
      });
      return;
    }
    final bookings = await _service.fetchVendorBookings(int.parse(vendorId));
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _loading = false;
    });
  }

  String _formatSlot(dynamic booking) {
    final type = booking['slotType']?.toString() ?? 'full_day';
    if (type == 'full_day') return 'Full Day';
    if (type == 'half_day') {
      final start = booking['startTime']?.toString() ?? '';
      final end = booking['endTime']?.toString() ?? '';
      return 'Half Day $start - $end';
    }
    final start = booking['startTime']?.toString() ?? '';
    final end = booking['endTime']?.toString() ?? '';
    return 'Hourly $start - $end';
  }

  Future<void> _updateStatus(int bookingId, String status) async {
    final res = await _service.updateBookingStatus(bookingId: bookingId, status: status);
    if (!mounted) return;
    if (res?.statusCode == 200) {
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to update status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Bookings")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text("No bookings yet"))
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      final status = (booking['status'] ?? 'pending').toString();
                      final date = booking['bookingDate']?.toString() ?? '';
                      final dateText = date.isNotEmpty
                          ? DateFormat('dd MMM yyyy').format(DateTime.parse(date))
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(child: Icon(Icons.event_available)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Date: $dateText", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(_formatSlot(booking), style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(status.toUpperCase()),
                                    backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(booking['notes'] ?? "No notes", style: const TextStyle(color: Colors.black87)),
                              if (status == 'pending') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _updateStatus(int.parse(booking['id'].toString()), 'cancelled'),
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        label: const Text("Reject"),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(int.parse(booking['id'].toString()), 'confirmed'),
                                        icon: const Icon(Icons.check),
                                        label: const Text("Accept"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (status == 'confirmed') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _updateStatus(int.parse(booking['id'].toString()), 'cancelled'),
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        label: const Text("Cancel"),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(int.parse(booking['id'].toString()), 'completed'),
                                        icon: const Icon(Icons.verified),
                                        label: const Text("Complete"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
