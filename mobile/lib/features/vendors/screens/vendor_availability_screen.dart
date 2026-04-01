import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/features/vendors/services/vendor_booking_service.dart';
import 'package:mobile/features/vendors/services/vendor_service.dart';

class VendorAvailabilityScreen extends StatefulWidget {
  const VendorAvailabilityScreen({super.key});

  @override
  State<VendorAvailabilityScreen> createState() => _VendorAvailabilityScreenState();
}

class _VendorAvailabilityScreenState extends State<VendorAvailabilityScreen> {
  final VendorService _vendorService = VendorService();
  final VendorBookingService _bookingService = VendorBookingService();
  final _storage = const FlutterSecureStorage();

  List<VendorModel> _services = [];
  VendorModel? _selectedService;
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = _startOfWeek(DateTime.now());
  bool _loading = true;
  List<dynamic> _blocked = [];
  List<dynamic> _booked = [];

  String _slotType = 'full_day';
  String _slotLabel = 'morning';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonController = TextEditingController();

  static DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final vendorId = await _storage.read(key: "userId");
    if (vendorId == null) {
      setState(() => _loading = false);
      return;
    }
    final services = await _vendorService.fetchMyServices(vendorId);
    if (!mounted) return;
    setState(() {
      _services = services;
      _selectedService = services.isNotEmpty ? services.first : null;
      _loading = false;
    });
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    if (_selectedService == null) return;
    final vendorId = await _storage.read(key: "userId");
    if (vendorId == null) return;
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final blocked = await _bookingService.fetchVendorUnavailableSlots(
      vendorId: int.parse(vendorId),
      serviceId: _selectedService!.id,
      date: date,
    );
    final booked = await _bookingService.fetchVendorBookedSlots(
      vendorId: int.parse(vendorId),
      serviceId: _selectedService!.id,
      date: date,
    );
    if (!mounted) return;
    setState(() {
      _blocked = blocked;
      _booked = booked;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _weekStart = _startOfWeek(picked);
      });
      _loadSlots();
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  Future<void> _blockSlot() async {
    if (_selectedService == null) return;
    final vendorId = await _storage.read(key: "userId");
    if (vendorId == null) return;

    String? startTime;
    String? endTime;
    String? slotLabel;
    if (_slotType == 'hourly') {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select start and end time")),
        );
        return;
      }
      startTime = _formatTime(_startTime!);
      endTime = _formatTime(_endTime!);
    } else if (_slotType == 'half_day') {
      slotLabel = _slotLabel;
    }

    final res = await _bookingService.blockVendorSlot(
      vendorId: int.parse(vendorId),
      serviceId: _selectedService!.id,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      slotType: _slotType,
      startTime: startTime,
      endTime: endTime,
      slotLabel: slotLabel,
      reason: _reasonController.text.trim(),
    );
    if (!mounted) return;
    if (res?.statusCode == 201) {
      _reasonController.clear();
      _startTime = null;
      _endTime = null;
      _loadSlots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to block slot")),
      );
    }
  }

  Future<void> _unblockSlot(int id) async {
    final res = await _bookingService.unblockVendorSlot(id);
    if (!mounted) return;
    if (res?.statusCode == 200) {
      _loadSlots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to unblock slot")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Availability")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<VendorModel>(
                    initialValue: _selectedService,
                    items: _services
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedService = val);
                      _loadSlots();
                    },
                    decoration: const InputDecoration(labelText: "Select Service"),
                  ),
                  const SizedBox(height: 12),
                  _buildCalendarHeader(),
                  const SizedBox(height: 10),
                  _buildWeekStrip(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _slotChip('full_day', "Full Day"),
                      const SizedBox(width: 10),
                      _slotChip('half_day', "Half Day"),
                      const SizedBox(width: 10),
                      _slotChip('hourly', "Hourly"),
                    ],
                  ),
                  if (_slotType == 'half_day') ...[
                    const SizedBox(height: 12),
                    Row(
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
                    ),
                  ],
                  if (_slotType == 'hourly') ...[
                    const SizedBox(height: 12),
                    Row(
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
                              if (picked != null) setState(() => _startTime = picked);
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
                              if (picked != null) setState(() => _endTime = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(labelText: "Reason (optional)"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _blockSlot,
                    child: const Text("Block Slot"),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _sectionHeader('Booked Slots', _booked.length),
                        if (_booked.isEmpty)
                          const Text("No bookings for this date", style: TextStyle(color: Colors.grey)),
                        ..._booked.map(_bookedCard),
                        const SizedBox(height: 16),
                        _sectionHeader('Blocked Slots', _blocked.length),
                        if (_blocked.isEmpty)
                          const Text("No blocked slots", style: TextStyle(color: Colors.grey)),
                        ..._blocked.map(_blockedCard),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedDate);
    return Row(
      children: [
        Expanded(
          child: Text(monthLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              _weekStart = _weekStart.subtract(const Duration(days: 7));
            });
            _loadSlots();
          },
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 7));
              _weekStart = _weekStart.add(const Duration(days: 7));
            });
            _loadSlots();
          },
          icon: const Icon(Icons.chevron_right),
        ),
        TextButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today, size: 16),
          label: const Text('Pick'),
        ),
      ],
    );
  }

  Widget _buildWeekStrip() {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    return Row(
      children: days.map((date) {
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadSlots();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
                ],
              ),
              child: Column(
                children: [
                  Text(DateFormat('E').format(date),
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('${date.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$count', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _bookedCard(dynamic slot) {
    final type = slot['slotType']?.toString() ?? 'slot';
    final start = slot['startTime']?.toString() ?? '';
    final end = slot['endTime']?.toString() ?? '';
    final label = type == 'full_day' ? 'Full Day' : "$type $start-$end";
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.event_busy, color: Colors.orange),
        title: Text(label),
        subtitle: Text('Status: ${slot['status'] ?? 'confirmed'}'),
      ),
    );
  }

  Widget _blockedCard(dynamic slot) {
    final type = slot['slotType']?.toString() ?? 'slot';
    final start = slot['startTime']?.toString() ?? '';
    final end = slot['endTime']?.toString() ?? '';
    final label = type == 'full_day' ? 'Full Day' : "$type $start-$end";
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(slot['reason'] ?? ''),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _unblockSlot(slot['id'] as int),
        ),
      ),
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
}
