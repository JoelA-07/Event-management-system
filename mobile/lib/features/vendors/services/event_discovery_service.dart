import 'package:mobile/features/halls/models/hall_model.dart';
import 'package:mobile/features/vendors/models/vendor_model.dart';
import 'package:mobile/features/halls/services/hall_service.dart';
import 'package:mobile/features/vendors/services/package_service.dart';
import 'package:mobile/features/vendors/services/vendor_service.dart';

class EventDiscoveryService {
  final HallService _hallService = HallService();
  final VendorService _vendorService = VendorService();
  final PackageService _packageService = PackageService();

  Future<Map<String, dynamic>> loadEventFeed(String eventType) async {
    final results = await Future.wait([
      _packageService.fetchPackages(eventType: eventType),
      _hallService.fetchHalls(eventType: eventType),
      _vendorService.fetchEventRecommendations(eventType),
    ]);

    return {
      'packages': results[0],
      'halls': results[1] as List<HallModel>,
      'vendors': results[2] as List<VendorModel>,
    };
  }
}
