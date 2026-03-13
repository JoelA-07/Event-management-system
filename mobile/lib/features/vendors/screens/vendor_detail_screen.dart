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

  @override
  void initState() {
    super.initState();
    if (widget.vendor.category == 'caterer') {
      _loadMenus();
    }
    _loadReviews();
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

  Future<void> _bookService() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date")),
      );
      return;
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

  double _averageRating() {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(0, (prev, r) => prev + (double.tryParse(r['rating'].toString()) ?? 0));
    return sum / _reviews.length;
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
                    onTap: _pickDate,
                  ),
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
}
