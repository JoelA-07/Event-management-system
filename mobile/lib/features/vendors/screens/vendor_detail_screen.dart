import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/features/vendors/providers/sample_cart_provider.dart';
import 'package:mobile/features/vendors/services/vendor_booking_service.dart';
import 'package:mobile/features/vendors/services/vendor_service.dart';
import 'package:mobile/features/reviews/services/review_service.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/vendors/screens/gallery_viewer_screen.dart';

class VendorDetailScreen extends StatefulWidget {
  final VendorModel vendor;
  const VendorDetailScreen({super.key, required this.vendor});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  bool _isBooking = false;
  DateTime? _selectedDate;
  final _notesController = TextEditingController();
  List<dynamic> _menus = [];
  bool _loadingMenus = false;
  List<dynamic> _reviews = [];
  bool _loadingReviews = false;
  int _rating = 5;
  final _reviewController = TextEditingController();
  String _slotType = 'full_day';
  String _slotLabel = 'morning';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loadingSlots = false;
  List<dynamic> _bookedSlots = [];
  List<dynamic> _blockedSlots = [];

  @override
  void initState() {
    super.initState();
    if (widget.vendor.category == 'caterer') {
      _loadMenus();
    }
    _loadReviews();
  }

  String _imageUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final base = AppConstants.baseUrl.replaceAll('/api', '');
    return "$base$raw";
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _loadMenus() async {
    setState(() => _loadingMenus = true);
    final menus = await VendorService().fetchMenusPublic(widget.vendor.vendorId.toString());
    if (!mounted) return;
    setState(() {
      _menus = menus;
      _loadingMenus = false;
    });
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final reviews = await ReviewService().fetchServiceReviews(widget.vendor.id);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _loadingReviews = false;
    });
  }

  double _averageRating() {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(0, (prev, r) => prev + (double.tryParse(r['rating'].toString()) ?? 0));
    return sum / _reviews.length;
  }

  Future<void> _loadVendorSlots() async {
    if (_selectedDate == null) return;
    setState(() => _loadingSlots = true);
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final bookingService = VendorBookingService();
    final booked = await bookingService.fetchVendorBookedSlots(
      vendorId: widget.vendor.vendorId,
      serviceId: widget.vendor.id,
      date: date,
    );
    final blocked = await bookingService.fetchVendorUnavailableSlots(
      vendorId: widget.vendor.vendorId,
      serviceId: widget.vendor.id,
      date: date,
    );
    if (!mounted) return;
    setState(() {
      _bookedSlots = booked;
      _blockedSlots = blocked;
      _loadingSlots = false;
    });
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  Future<void> _bookService() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date")),
      );
      return;
    }

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

    setState(() => _isBooking = true);
    const storage = FlutterSecureStorage();
    final customerId = await storage.read(key: "userId");
    if (!mounted) return;
    if (customerId == null) {
      setState(() => _isBooking = false);
      return;
    }

    final res = await VendorBookingService().createBooking(
      vendorId: widget.vendor.vendorId,
      serviceId: widget.vendor.id,
      customerId: int.parse(customerId),
      bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      notes: _notesController.text.trim(),
      slotType: _slotType,
      startTime: startTime,
      endTime: endTime,
      slotLabel: slotLabel,
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (res?.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking request sent"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Booking failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                _imageUrl(widget.vendor.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.vendor.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    "Starting at Rs ${widget.vendor.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.vendor.description),
                  const SizedBox(height: 20),
                  if (widget.vendor.portfolio.isNotEmpty) ...[
                    const Text("Portfolio", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildPortfolioGallery(),
                    const SizedBox(height: 20),
                  ],
                  if (widget.vendor.category == 'caterer') ...[
                    const Text("Menu Packages", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildMenuList(context),
                    const SizedBox(height: 20),
                  ],
                  const Text("Reviews", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildReviewSummary(),
                  const SizedBox(height: 8),
                  _buildReviewList(),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _showReviewDialog,
                    child: const Text("Write a Review"),
                  ),
                  const SizedBox(height: 20),
                  const Text("Select Booking Date", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                    onTap: () async {
                      await _pickDate();
                      if (_selectedDate != null) {
                        _loadVendorSlots();
                      }
                    },
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Custom request (optional)",
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isBooking
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _bookService,
                          child: const Text("BOOK THIS SERVICE"),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    if (_loadingMenus) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_menus.isEmpty) {
      return const Text("No menus available for sampling");
    }
    final cart = context.read<SampleCartProvider>();
    return Column(
      children: _menus.map((menu) {
        final isSample = menu['isSampleAvailable'] == true;
        final price = (menu['samplePrice'] ?? menu['pricePerPlate'] ?? 0).toString();
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu, color: AppTheme.primaryColor),
            title: Text(menu['packageName'] ?? 'Menu Package'),
            subtitle: Text(menu['menuItems'] ?? ''),
            trailing: SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerRight,
                child: isSample
                    ? ElevatedButton(
                        onPressed: () {
                          cart.addToCart(
                            SampleCartItem(
                              menuId: menu['id'] as int,
                              name: menu['packageName'] ?? 'Menu Package',
                              price: double.tryParse(price) ?? 0,
                              vendorId: widget.vendor.vendorId,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Added to sample cart")),
                          );
                        },
                        child: Text("Add Rs $price"),
                      )
                    : const Text("No sample"),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewSummary() {
    final avg = _averageRating();
    return Row(
      children: [
        Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _buildStars(avg.round()),
        const SizedBox(width: 8),
        Text("(${_reviews.length})", style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildReviewList() {
    if (_loadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reviews.isEmpty) {
      return const Text("No reviews yet", style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: _reviews.take(6).map((r) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text((r['User']?['name'] ?? 'U')[0])),
            title: Text(r['User']?['name'] ?? 'User'),
            subtitle: Text(r['comment'] ?? ''),
            trailing: _buildStars(int.tryParse(r['rating'].toString()) ?? 0),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < count ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  void _showReviewDialog() {
    _rating = 5;
    _reviewController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text("Rate this service"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setLocalState(() => _rating = star),
                    icon: Icon(
                      _rating >= star ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Write feedback"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(onPressed: _submitReview, child: const Text("Submit")),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    final res = await ReviewService().createReview(
      serviceId: widget.vendor.id,
      rating: _rating,
      comment: _reviewController.text.trim(),
    );
    if (!mounted) return;
    if (res?.statusCode == 201) {
      Navigator.pop(context);
      _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?.data['message'] ?? "Failed to submit review")),
      );
    }
  }

  Widget _buildPortfolioGallery() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.vendor.portfolio.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final img = _imageUrl(widget.vendor.portfolio[index]);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GalleryViewerScreen(
                  images: widget.vendor.portfolio,
                  initialIndex: index,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                img,
                width: 140,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 140,
                  height: 110,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          );
        },
      ),
    );
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
    if (_selectedDate == null) {
      return const Text("Select a date to view booked slots", style: TextStyle(color: Colors.grey));
    }
    if (_loadingSlots) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookedSlots.isEmpty && _blockedSlots.isEmpty) {
      return const Text("No slots booked or blocked for this date", style: TextStyle(color: Colors.green));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ..._bookedSlots.map((slot) {
          final type = slot['slotType']?.toString() ?? 'slot';
          final start = slot['startTime']?.toString() ?? '';
          final end = slot['endTime']?.toString() ?? '';
          final label = type == 'full_day' ? 'Booked: Full Day' : "Booked: $type $start-$end";
          return Chip(
            label: Text(label, style: const TextStyle(fontSize: 11)),
            backgroundColor: Colors.red.shade50,
            labelStyle: TextStyle(color: Colors.red.shade700),
          );
        }),
        ..._blockedSlots.map((slot) {
          final type = slot['slotType']?.toString() ?? 'slot';
          final start = slot['startTime']?.toString() ?? '';
          final end = slot['endTime']?.toString() ?? '';
          final label = type == 'full_day' ? 'Blocked: Full Day' : "Blocked: $type $start-$end";
          return Chip(
            label: Text(label, style: const TextStyle(fontSize: 11)),
            backgroundColor: Colors.orange.shade50,
            labelStyle: TextStyle(color: Colors.orange.shade700),
          );
        }),
      ],
    );
  }
}
