import 'package:flutter/material.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/organizer/screens/dispute_detail_screen.dart';
import 'package:mobile/features/organizer/screens/review_detail_screen.dart';
import 'package:mobile/features/organizer/services/organizer_admin_service.dart';

class OrganizerAdminDashboard extends StatefulWidget {
  const OrganizerAdminDashboard({super.key});

  @override
  State<OrganizerAdminDashboard> createState() => _OrganizerAdminDashboardState();
}

class _OrganizerAdminDashboardState extends State<OrganizerAdminDashboard> with SingleTickerProviderStateMixin {
  final OrganizerAdminService _service = OrganizerAdminService();
  late final TabController _tabController;
  bool _loadMoreScheduled = false;

  final ScrollController _approvalsController = ScrollController();
  final ScrollController _payoutsController = ScrollController();
  final ScrollController _disputesController = ScrollController();
  final ScrollController _reviewsController = ScrollController();

  List<dynamic> _pendingHalls = [];
  List<dynamic> _pendingServices = [];
  bool _approvalsLoading = true;
  bool _approvalsLoadingMore = false;
  int _approvalsPage = 1;
  int _approvalsTotalPages = 1;
  String? _approvalsError;

  List<dynamic> _payments = [];
  List<dynamic> _payouts = [];
  bool _payoutsLoading = true;
  bool _payoutsLoadingMore = false;
  int _payoutsPage = 1;
  int _payoutsTotalPages = 1;
  String? _payoutsError;

  List<dynamic> _disputes = [];
  bool _disputesLoading = true;
  bool _disputesLoadingMore = false;
  int _disputesPage = 1;
  int _disputesTotalPages = 1;
  String? _disputesError;

  List<dynamic> _reports = [];
  bool _reviewsLoading = true;
  bool _reviewsLoadingMore = false;
  int _reviewsPage = 1;
  int _reviewsTotalPages = 1;
  String? _reviewsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _approvalsController.addListener(() => _onScroll(_approvalsController, _loadApprovalsMore));
    _payoutsController.addListener(() => _onScroll(_payoutsController, _loadPayoutsMore));
    _disputesController.addListener(() => _onScroll(_disputesController, _loadDisputesMore));
    _reviewsController.addListener(() => _onScroll(_reviewsController, _loadReviewsMore));

    _loadApprovals(reset: true);
    _loadPayouts(reset: true);
    _loadDisputes(reset: true);
    _loadReviews(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _approvalsController.dispose();
    _payoutsController.dispose();
    _disputesController.dispose();
    _reviewsController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollController controller, VoidCallback onLoadMore) {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - 200) {
      if (_loadMoreScheduled) return;
      _loadMoreScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMoreScheduled = false;
        if (!mounted) return;
        onLoadMore();
      });
    }
  }

  Future<void> _loadApprovals({bool reset = false}) async {
    if (reset) {
      setState(() {
        _approvalsLoading = true;
        _approvalsPage = 1;
        _approvalsError = null;
      });
    } else {
      if (_approvalsLoadingMore || _approvalsPage > _approvalsTotalPages) return;
      setState(() => _approvalsLoadingMore = true);
    }

    try {
      final data = await _service.fetchApprovals(page: _approvalsPage, limit: 20);
      final hallsBlock = data['halls'];
      final servicesBlock = data['services'];

      List<dynamic> halls;
      List<dynamic> services;
      int totalPages = 1;

      if (hallsBlock is Map && hallsBlock['data'] is List) {
        halls = List<dynamic>.from(hallsBlock['data']);
        totalPages = hallsBlock['meta']?['totalPages'] ?? 1;
      } else {
        halls = List<dynamic>.from(hallsBlock ?? []);
      }

      if (servicesBlock is Map && servicesBlock['data'] is List) {
        services = List<dynamic>.from(servicesBlock['data']);
        totalPages = servicesBlock['meta']?['totalPages'] ?? totalPages;
      } else {
        services = List<dynamic>.from(servicesBlock ?? []);
      }

      setState(() {
        _pendingHalls = reset ? halls : [..._pendingHalls, ...halls];
        _pendingServices = reset ? services : [..._pendingServices, ...services];
        _approvalsTotalPages = totalPages;
        _approvalsPage += 1;
        _approvalsLoading = false;
        _approvalsLoadingMore = false;
      });
    } catch (error) {
      setState(() {
        _approvalsLoading = false;
        _approvalsLoadingMore = false;
        _approvalsError = 'Failed to load approvals. Please try again.';
      });
    }
  }

  void _loadApprovalsMore() => _loadApprovals(reset: false);

  Future<void> _loadPayouts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _payoutsLoading = true;
        _payoutsPage = 1;
        _payoutsError = null;
      });
    } else {
      if (_payoutsLoadingMore || _payoutsPage > _payoutsTotalPages) return;
      setState(() => _payoutsLoadingMore = true);
    }

    try {
      final data = await _service.fetchPayouts(page: _payoutsPage, limit: 20);
      final paymentsBlock = data['payments'];
      final payoutsBlock = data['payouts'];

      List<dynamic> payments;
      List<dynamic> payouts;
      int totalPages = 1;

      if (paymentsBlock is Map && paymentsBlock['data'] is List) {
        payments = List<dynamic>.from(paymentsBlock['data']);
        totalPages = paymentsBlock['meta']?['totalPages'] ?? 1;
      } else {
        payments = List<dynamic>.from(paymentsBlock ?? []);
      }

      if (payoutsBlock is Map && payoutsBlock['data'] is List) {
        payouts = List<dynamic>.from(payoutsBlock['data']);
        totalPages = payoutsBlock['meta']?['totalPages'] ?? totalPages;
      } else {
        payouts = List<dynamic>.from(payoutsBlock ?? []);
      }

      setState(() {
        _payments = reset ? payments : [..._payments, ...payments];
        _payouts = reset ? payouts : [..._payouts, ...payouts];
        _payoutsTotalPages = totalPages;
        _payoutsPage += 1;
        _payoutsLoading = false;
        _payoutsLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _payoutsLoading = false;
        _payoutsLoadingMore = false;
        _payoutsError = 'Failed to load payouts. Please try again.';
      });
    }
  }

  void _loadPayoutsMore() => _loadPayouts(reset: false);

  Future<void> _loadDisputes({bool reset = false}) async {
    if (reset) {
      setState(() {
        _disputesLoading = true;
        _disputesPage = 1;
        _disputesError = null;
      });
    } else {
      if (_disputesLoadingMore || _disputesPage > _disputesTotalPages) return;
      setState(() => _disputesLoadingMore = true);
    }

    try {
      final data = await _service.fetchDisputes(status: 'open', page: _disputesPage, limit: 20);
      final items = List<dynamic>.from(data['data'] ?? []);
      final totalPages = data['meta']?['totalPages'] ?? 1;

      setState(() {
        _disputes = reset ? items : [..._disputes, ...items];
        _disputesTotalPages = totalPages;
        _disputesPage += 1;
        _disputesLoading = false;
        _disputesLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _disputesLoading = false;
        _disputesLoadingMore = false;
        _disputesError = 'Failed to load disputes. Please try again.';
      });
    }
  }

  void _loadDisputesMore() => _loadDisputes(reset: false);

  Future<void> _loadReviews({bool reset = false}) async {
    if (reset) {
      setState(() {
        _reviewsLoading = true;
        _reviewsPage = 1;
        _reviewsError = null;
      });
    } else {
      if (_reviewsLoadingMore || _reviewsPage > _reviewsTotalPages) return;
      setState(() => _reviewsLoadingMore = true);
    }

    try {
      final data = await _service.fetchReviewReports(page: _reviewsPage, limit: 20);
      final items = List<dynamic>.from(data['data'] ?? []);
      final totalPages = data['meta']?['totalPages'] ?? 1;

      setState(() {
        _reports = reset ? items : [..._reports, ...items];
        _reviewsTotalPages = totalPages;
        _reviewsPage += 1;
        _reviewsLoading = false;
        _reviewsLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _reviewsLoading = false;
        _reviewsLoadingMore = false;
        _reviewsError = 'Failed to load reviews. Please try again.';
      });
    }
  }

  void _loadReviewsMore() => _loadReviews(reset: false);

  Future<void> _showReasonDialog(BuildContext context, void Function(String? reason) onSubmit) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add reason (optional)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason or note'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSubmit(controller.text.trim().isEmpty ? null : controller.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Organizer Admin'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Approvals'),
            Tab(text: 'Payouts'),
            Tab(text: 'Disputes'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovals(),
          _buildPayouts(),
          _buildDisputes(),
          _buildReviews(),
        ],
      ),
    );
  }

  Widget _buildApprovals() {
    if (_approvalsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_approvalsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_approvalsError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _loadApprovals(reset: true), child: const Text('Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadApprovals(reset: true),
      child: ListView(
        controller: _approvalsController,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Pending Halls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_pendingHalls.isEmpty) const Text('No pending halls.', style: TextStyle(color: Colors.grey)),
          ..._pendingHalls.map((hall) => _approvalCard(
                title: hall['name'] ?? 'Hall',
                subtitle: hall['location'] ?? '',
                onApprove: () async {
                  await _service.updateHallApproval(hall['id'], 'approved');
                  _loadApprovals(reset: true);
                },
                onReject: () => _showReasonDialog(context, (reason) async {
                  await _service.updateHallApproval(hall['id'], 'rejected', reason: reason);
                  _loadApprovals(reset: true);
                }),
              )),
          const SizedBox(height: 24),
          const Text('Pending Vendor Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_pendingServices.isEmpty) const Text('No pending services.', style: TextStyle(color: Colors.grey)),
          ..._pendingServices.map((service) => _approvalCard(
                title: service['name'] ?? 'Service',
                subtitle: service['category'] ?? '',
                onApprove: () async {
                  await _service.updateServiceApproval(service['id'], 'approved');
                  _loadApprovals(reset: true);
                },
                onReject: () => _showReasonDialog(context, (reason) async {
                  await _service.updateServiceApproval(service['id'], 'rejected', reason: reason);
                  _loadApprovals(reset: true);
                }),
              )),
          if (_approvalsLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _approvalCard({required String title, required String subtitle, required VoidCallback onApprove, required VoidCallback onReject}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: SizedBox(
          width: 170,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 72,
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Reject', maxLines: 1, softWrap: false),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 82,
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Approve', maxLines: 1, softWrap: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayouts() {
    if (_payoutsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_payoutsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_payoutsError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _loadPayouts(reset: true), child: const Text('Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadPayouts(reset: true),
      child: ListView(
        controller: _payoutsController,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_payments.isEmpty) const Text('No payments yet.', style: TextStyle(color: Colors.grey)),
          ..._payments.map((p) => _simpleRow(
                title: 'Payment #${p['id']}',
                subtitle: 'Status: ${p['status']} | Paid: Rs ${p['paidAmount']}',
              )),
          const SizedBox(height: 24),
          const Text('Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_payouts.isEmpty) const Text('No payouts yet.', style: TextStyle(color: Colors.grey)),
          ..._payouts.map((p) => _simpleRow(
                title: 'Payout #${p['id']}',
                subtitle: 'Vendor: ${p['vendorId']} | Amount: Rs ${p['amount']}',
              )),
          if (_payoutsLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDisputes() {
    if (_disputesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_disputesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_disputesError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _loadDisputes(reset: true), child: const Text('Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadDisputes(reset: true),
      child: ListView(
        controller: _disputesController,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Open Disputes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_disputes.isEmpty) const Text('No open disputes.', style: TextStyle(color: Colors.grey)),
          ..._disputes.map((d) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('Dispute #${d['id']}'),
                  subtitle: Text(d['reason'] ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final refreshed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DisputeDetailScreen(dispute: Map<String, dynamic>.from(d)),
                      ),
                    );
                    if (refreshed == true && mounted) _loadDisputes(reset: true);
                  },
                ),
              )),
          if (_disputesLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    if (_reviewsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reviewsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_reviewsError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _loadReviews(reset: true), child: const Text('Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadReviews(reset: true),
      child: ListView(
        controller: _reviewsController,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Reported Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_reports.isEmpty) const Text('No reported reviews.', style: TextStyle(color: Colors.grey)),
          ..._reports.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('Report #${r['id']} (Review ${r['reviewId']})'),
                  subtitle: Text(r['reason'] ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final refreshed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewDetailScreen(report: Map<String, dynamic>.from(r)),
                      ),
                    );
                    if (refreshed == true && mounted) _loadReviews(reset: true);
                  },
                ),
              )),
          if (_reviewsLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _simpleRow({required String title, required String subtitle}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
