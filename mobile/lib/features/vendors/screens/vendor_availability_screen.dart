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
  DateTime? _selectedDate;
  bool _loading = true;
  List<dynamic> _blocked = [];

  String _slotType = 'full_day';
  String _slotLabel = 'morning';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonController = TextEditingController();

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
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadBlocked();
    }
  }

  Future<void> _loadBlocked() async {
    if (_selectedService == null || _selectedDate == null) return;
    final vendorId = await _storage.read(key: "userId");
    if (vendorId == null) return;
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final blocked = await _bookingService.fetchVendorUnavailableSlots(
      vendorId: int.parse(vendorId),
      serviceId: _selectedService!.id,
      date: date,
    );
    if (!mounted) return;
    setState(() => _blocked = blocked);
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  Future<void> _blockSlot() async {
    if (_selectedService == null || _selectedDate == null) return;
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
      date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      slotType: _slotType,
      startTime: startTime,
      endTime: endTime,
      slotLabel: slotLabel,
      reason: _reasonController.text.trim(),
    );
    if (!mounted) return;
    if (res?.statusCode == 201) {
      _reasonController.clear();
      _loadBlocked();
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
      _loadBlocked();
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
                      _loadBlocked();
                    },
                    decoration: const InputDecoration(labelText: "Select Service"),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    title: Text(
                      _selectedDate == null
                          ? "Choose a date"
                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    ),
                    trailing: const Icon(Icons.edit, size: 16),
                    onTap: _pickDate,
                  ),
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
                  const Text("Blocked Slots", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _blocked.isEmpty
                        ? const Text("No blocked slots")
                        : ListView.builder(
                            itemCount: _blocked.length,
                            itemBuilder: (context, index) {
                              final slot = _blocked[index];
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
                            },
                          ),
                  ),
                ],
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
