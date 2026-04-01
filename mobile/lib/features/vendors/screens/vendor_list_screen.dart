import 'package:flutter/material.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/features/vendors/services/vendor_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/vendors/screens/vendor_detail_screen.dart';

class VendorListScreen extends StatefulWidget {
  final String category;
  const VendorListScreen({super.key, required this.category});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final VendorService _service = VendorService();
  final ScrollController _scrollController = ScrollController();
  List<VendorModel> _vendors = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    final result = await _service.fetchServicesPage(
      category: widget.category,
      page: _page,
      limit: _limit,
    );

    final items = List<VendorModel>.from(result['items'] as List);
    final meta = Map<String, dynamic>.from(result['meta'] as Map);
    final totalPages = (meta['totalPages'] ?? 1) as int;

    setState(() {
      if (reset) {
        _vendors = items;
      } else {
        _vendors = [..._vendors, ...items];
      }
      _page += 1;
      _hasMore = _page <= totalPages;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _loadMore() async => _load(reset: false);

  @override
  Widget build(BuildContext context) {
    final title = "${widget.category[0].toUpperCase()}${widget.category.substring(1)}";
    return Scaffold(
      appBar: AppBar(title: Text("$title Services")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vendors.isEmpty
              ? const Center(child: Text("No vendors available in this category."))
              : RefreshIndicator(
                  onRefresh: () => _load(reset: true),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _vendors.length + (_loadingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _vendors.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildVendorCard(context, _vendors[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorModel vendor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: vendor)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10243C).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  vendor.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.blueGrey.shade50,
                    child: const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Starting at Rs ${vendor.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
