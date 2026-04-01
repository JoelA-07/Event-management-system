import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/bookings/services/booking_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/payments/screens/payment_summary_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _service = BookingService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _bookings = [];
  String _role = '';
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _limit = 20;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadBookings(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _page <= _totalPages) {
        _loadBookings(reset: false);
      }
    }
  }

  Future<void> _loadBookings({bool reset = true}) async {
    const storage = FlutterSecureStorage();
    final id = await storage.read(key: "userId");
    final role = await storage.read(key: "role");
    if (id == null || role == null) {
      setState(() {
        _loading = false;
        _bookings = [];
      });
      return;
    }

    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
      });
    } else {
      if (_loadingMore || _page > _totalPages) return;
      setState(() => _loadingMore = true);
    }

    final res = await _service.fetchUserBookingsPaged(
      userId: int.parse(id),
      role: role,
      page: _page,
      limit: _limit,
    );

    final items = List<dynamic>.from(res['data'] ?? []);
    final totalPages = res['meta']?['totalPages'] ?? 1;

    setState(() {
      _role = role;
      _bookings = reset ? items : [..._bookings, ...items];
      _totalPages = totalPages;
      _page += 1;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _showCancelDialog(dynamic booking) async {
    final reasonController = TextEditingController();
    final refundController = TextEditingController();
    bool autoRefund = true;
    String refundMethod = 'manual';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Cancel booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason (optional)'),
                ),
                if (_role == 'organizer') ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: autoRefund,
                    onChanged: (val) => setLocal(() => autoRefund = val),
                    title: const Text('Auto refund paid amount'),
                  ),
                  if (!autoRefund) ...[
                    TextField(
                      controller: refundController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Refund amount (optional)'),
                    ),
                    DropdownButtonFormField<String>(
                      value: refundMethod,
                      items: const [
                        DropdownMenuItem(value: 'manual', child: Text('Manual')),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'online', child: Text('Online')),
                      ],
                      onChanged: (val) => setLocal(() => refundMethod = val ?? 'manual'),
                      decoration: const InputDecoration(labelText: 'Refund method'),
                    ),
                  ]
                ]
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final refundAmount = refundController.text.trim().isEmpty
                    ? null
                    : double.tryParse(refundController.text.trim());
                final res = await _service.cancelBooking(
                  bookingId: int.parse(booking['id'].toString()),
                  reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                  refundAmount: refundAmount,
                  refundMethod: refundMethod,
                  autoRefund: _role == 'organizer' ? autoRefund : null,
                );
                if (!mounted) return;
                if (res?.statusCode == 200) {
                  _loadBookings(reset: true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res?.data['message'] ?? 'Cancel failed')),
                  );
                }
              },
              child: const Text('Confirm cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'confirmed') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Event History", style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No bookings found yet.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadBookings(reset: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _bookings.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final booking = _bookings[index];
                      final hall = booking['Hall'];
                      final status = booking['status']?.toString() ?? 'confirmed';

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
                                "Status: ${status.toUpperCase()}",
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: [
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
                                  if (status != 'cancelled')
                                    TextButton.icon(
                                      onPressed: () => _showCancelDialog(booking),
                                      icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                                      label: const Text('Cancel'),
                                    ),
                                ],
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
                  ),
                ),
    );
  }
}
