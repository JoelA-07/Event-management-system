import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/hall_model.dart';
import '../providers/booking_provider.dart';
import '../utils/theme.dart';

class HallDetailScreen extends StatefulWidget {
  final HallModel hall;
  const HallDetailScreen({super.key, required this.hall});

  @override
  State<HallDetailScreen> createState() => _HallDetailScreenState();
}

class _HallDetailScreenState extends State<HallDetailScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Fetch dates already booked for this specific hall from the backend
    Future.microtask(() =>
        context.read<BookingProvider>().loadBookedDates(widget.hall.id));
  }

  // Function to handle the booking process
  void _confirmBooking() async {
    if (_selectedDay == null) return;

    final bookingProvider = context.read<BookingProvider>();
    
    // In a real app, you'd get the actual logged-in user ID from your AuthProvider or Storage
    // For now, we use a placeholder '1'. 
    // You can later use: String? userId = await _storage.read(key: "userId");
    int customerId = 1; 

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
    );

    String? error = await bookingProvider.bookHall(
      widget.hall.id,
      customerId,
      formattedDate,
    );

    if (mounted) Navigator.pop(context); // Close loading dialog

    if (error == null) {
      // Success
      _showSuccessDialog();
    } else {
      // Failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Your booking is confirmed! Our team will contact you shortly for further details.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            child: const Text("Great!"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. COLLAPSING IMAGE HEADER
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'hall-img-${widget.hall.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(widget.hall.imageUrl, fit: BoxFit.cover),
                    // Dark gradient overlay for text readability
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. HALL INFO & BOOKING CALENDAR
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.hall.name,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "₹${widget.hall.pricePerDay}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Capacity and Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.accentColor, size: 20),
                        const SizedBox(width: 5),
                        Text(widget.hall.location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(width: 20),
                        const Icon(Icons.people, color: AppTheme.accentColor, size: 20),
                        const SizedBox(width: 5),
                        Text("${widget.hall.capacity} Guests", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    
                    const Divider(height: 40),

                    const Text(
                      "Select an Available Date",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    // THE CALENDAR
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        
                        // CRITICAL: This disables dates already booked in your MySQL DB
                        enabledDayPredicate: (day) {
                          String dateStr = DateFormat('yyyy-MM-dd').format(day);
                          return !bookingProvider.bookedDates.contains(dateStr);
                        },

                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        
                        calendarStyle: const CalendarStyle(
                          selectedDecoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                          disabledTextStyle: TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough),
                        ),
                        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "About this Hall",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.hall.description,
                      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                    ),
                    
                    const SizedBox(height: 120), // Extra space for scrolling above the button
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),

      // 3. FIXED BOTTOM BOOKING BUTTON
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedDay == null || bookingProvider.isLoading 
                ? null 
                : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(
              _selectedDay == null 
                  ? "Select a Date to Book" 
                  : "Book for ${DateFormat('dd MMM yyyy').format(_selectedDay!)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}