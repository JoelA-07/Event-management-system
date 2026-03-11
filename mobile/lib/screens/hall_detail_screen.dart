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
  String _slotType = 'full_day';
  String _slotLabel = 'morning';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loadingSlots = false;
  List<dynamic> _bookedSlots = [];

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
    final userIdString = await _storage.read(key: "userId");
    if (!mounted) return;
    if (userIdString == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again to continue")),
      );
      return;
    }
    final customerId = int.parse(userIdString);

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    String? startTime;
    String? endTime;
    String? slotLabel;

    if (_slotType == 'hourly') {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select start and end time")),
        );
        return;
      }
      startTime = _formatTime(_startTime!);
      endTime = _formatTime(_endTime!);
    } else if (_slotType == 'half_day') {
      slotLabel = _slotLabel;
    }

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
      slotType: _slotType,
      startTime: startTime,
      endTime: endTime,
      slotLabel: slotLabel,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

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
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
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

                        onDaySelected: (selectedDay, focusedDay) async {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          await _loadBookedSlots();
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
                      "Choose Time Slot",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildSlotTypeSelector(),
                    if (_slotType == 'half_day') ...[
                      const SizedBox(height: 12),
                      _buildHalfDaySelector(),
                    ],
                    if (_slotType == 'hourly') ...[
                      const SizedBox(height: 12),
                      _buildHourlySelector(context),
                    ],
                    const SizedBox(height: 12),
                    _buildBookedSlotsHint(),

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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
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

  Future<void> _loadBookedSlots() async {
    if (_selectedDay == null) return;
    setState(() => _loadingSlots = true);
    final date = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final slots = await context.read<BookingProvider>().fetchBookedSlots(widget.hall.id, date);
    if (!mounted) return;
    setState(() {
      _bookedSlots = slots;
      _loadingSlots = false;
    });
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  Widget _buildSlotTypeSelector() {
    return Row(
      children: [
        _slotChip('full_day', "Full Day"),
        const SizedBox(width: 10),
        _slotChip('half_day', "Half Day"),
        const SizedBox(width: 10),
        _slotChip('hourly', "Hourly"),
      ],
    );
  }

  Widget _slotChip(String value, String label) {
    final isSelected = _slotType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      onSelected: (_) {
        setState(() {
          _slotType = value;
          _startTime = null;
          _endTime = null;
        });
      },
    );
  }

  Widget _buildHalfDaySelector() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text("Morning"),
          selected: _slotLabel == 'morning',
          onSelected: (_) => setState(() => _slotLabel = 'morning'),
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text("Evening"),
          selected: _slotLabel == 'evening',
          onSelected: (_) => setState(() => _slotLabel = 'evening'),
        ),
      ],
    );
  }

  Widget _buildHourlySelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_startTime == null ? "Start Time" : _startTime!.format(context)),
            leading: const Icon(Icons.schedule, color: AppTheme.primaryColor),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => _startTime = picked);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_endTime == null ? "End Time" : _endTime!.format(context)),
            leading: const Icon(Icons.schedule_outlined, color: AppTheme.primaryColor),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => _endTime = picked);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookedSlotsHint() {
    if (_selectedDay == null) {
      return const Text("Select a date to view booked slots", style: TextStyle(color: Colors.grey));
    }
    if (_loadingSlots) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookedSlots.isEmpty) {
      return const Text("No slots booked for this date", style: TextStyle(color: Colors.green));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _bookedSlots.map((slot) {
        final type = slot['slotType']?.toString() ?? 'slot';
        final start = slot['startTime']?.toString() ?? '';
        final end = slot['endTime']?.toString() ?? '';
        final label = type == 'full_day' ? 'Full Day' : "$type $start-$end";
        return Chip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          backgroundColor: Colors.red.shade50,
          labelStyle: TextStyle(color: Colors.red.shade700),
        );
      }).toList(),
    );
  }
}

