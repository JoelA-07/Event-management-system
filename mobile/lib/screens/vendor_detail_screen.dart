import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/vendor_model.dart';
import '../providers/sample_cart_provider.dart';
import '../services/vendor_booking_service.dart';
import '../services/vendor_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.vendor.category == 'caterer') {
      _loadMenus();
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
                  if (widget.vendor.category == 'caterer') ...[
                    const Text("Menu Packages", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildMenuList(context),
                    const SizedBox(height: 20),
                  ],
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
            trailing: isSample
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
        );
      }).toList(),
    );
  }
}
