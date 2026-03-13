import 'package:flutter/material.dart';
import 'package:mobile/core/models/event_type_model.dart';
import 'package:mobile/features/halls/models/hall_model.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/features/vendors/services/event_discovery_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/halls/screens/hall_detail_screen.dart';

class EventResultsScreen extends StatefulWidget {
  final EventTypeModel eventType;
  const EventResultsScreen({super.key, required this.eventType});

  @override
  State<EventResultsScreen> createState() => _EventResultsScreenState();
}

class _EventResultsScreenState extends State<EventResultsScreen> {
  late Future<Map<String, dynamic>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = EventDiscoveryService().loadEventFeed(widget.eventType.key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.eventType.title} Plans")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feed = snapshot.data ?? {};
          final packages = List<dynamic>.from(feed['packages'] ?? []);
          final halls = List<HallModel>.from(feed['halls'] ?? []);
          final vendors = List<VendorModel>.from(feed['vendors'] ?? []);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _feedFuture = EventDiscoveryService().loadEventFeed(widget.eventType.key);
              });
              await _feedFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildThemeBanner(),
                const SizedBox(height: 20),
                _sectionTitle("Elite ${widget.eventType.title} Packages"),
                const SizedBox(height: 10),
                if (packages.isEmpty)
                  _emptyHint("No curated packages yet. Explore individual services below.")
                else
                  ...packages.map(_packageCard),
                const SizedBox(height: 20),
                _sectionTitle("${widget.eventType.title} Venues"),
                const SizedBox(height: 10),
                if (halls.isEmpty)
                  _emptyHint("No event-specific halls found. Showing vendor options below.")
                else
                  ...halls.take(4).map((hall) => _hallCard(context, hall)),
                const SizedBox(height: 20),
                _sectionTitle("Recommended Services"),
                const SizedBox(height: 10),
                if (vendors.isEmpty)
                  _emptyHint("No matching vendor services yet.")
                else
                  ...vendors.take(8).map(_vendorCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: widget.eventType.bannerGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(widget.eventType.icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${widget.eventType.title} theme activated.\nPackages first, then individual services.",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _emptyHint(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }

  Widget _packageCard(dynamic pkg) {
    final title = pkg['title']?.toString() ?? 'Elite Package';
    final desc = pkg['description']?.toString() ?? 'Bundle offer';
    final rawPrice = pkg['discountedPrice'] ?? pkg['totalPrice'] ?? '0';
    final priceText = "Rs ${rawPrice.toString()}";
    return _buildResultCard(title, desc, priceText, Icons.card_giftcard);
  }

  Widget _hallCard(BuildContext context, HallModel hall) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HallDetailScreen(hall: hall)),
      ),
      child: _buildResultCard(
        hall.name,
        "${hall.location} - Capacity ${hall.capacity}",
        "Rs ${hall.pricePerDay.toStringAsFixed(0)}",
        Icons.business,
      ),
    );
  }

  Widget _vendorCard(VendorModel vendor) {
    return _buildResultCard(
      vendor.name,
      "${vendor.category.toUpperCase()} - ${vendor.description}",
      "Rs ${vendor.price.toStringAsFixed(0)}",
      Icons.storefront,
    );
  }

  Widget _buildResultCard(String name, String sub, String price, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}

