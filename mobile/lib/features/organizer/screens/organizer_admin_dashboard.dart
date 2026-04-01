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

  List<dynamic> _payments = [];
  List<dynamic> _payouts = [];
  bool _payoutsLoading = true;
  bool _payoutsLoadingMore = false;
  int _payoutsPage = 1;
  int _payoutsTotalPages = 1;

  List<dynamic> _disputes = [];
  bool _disputesLoading = true;
  bool _disputesLoadingMore = false;
  int _disputesPage = 1;
  int _disputesTotalPages = 1;

  List<dynamic> _reports = [];
  bool _reviewsLoading = true;
  bool _reviewsLoadingMore = false;
  int _reviewsPage = 1;
  int _reviewsTotalPages = 1;

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
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      onLoadMore();
    }
  }

  Future<void> _loadApprovals({bool reset = false}) async {
    if (reset) {
      setState(() {
        _approvalsLoading = true;
        _approvalsPage = 1;
      });
    } else {
      if (_approvalsLoadingMore || _approvalsPage > _approvalsTotalPages) return;
      setState(() => _approvalsLoadingMore = true);
    }

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
  }

  void _loadApprovalsMore() => _loadApprovals(reset: false);

  Future<void> _loadPayouts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _payoutsLoading = true;
        _payoutsPage = 1;
      });
    } else {
      if (_payoutsLoadingMore || _payoutsPage > _payoutsTotalPages) return;
      setState(() => _payoutsLoadingMore = true);
    }

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
  }

  void _loadPayoutsMore() => _loadPayouts(reset: false);

  Future<void> _loadDisputes({bool reset = false}) async {
    if (reset) {
      setState(() {
        _disputesLoading = true;
        _disputesPage = 1;
      });
    } else {
      if (_disputesLoadingMore || _disputesPage > _disputesTotalPages) return;
      setState(() => _disputesLoadingMore = true);
    }

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
  }

  void _loadDisputesMore() => _loadDisputes(reset: false);

  Future<void> _loadReviews({bool reset = false}) async {
    if (reset) {
      setState(() {
        _reviewsLoading = true;
        _reviewsPage = 1;
      });
    } else {
      if (_reviewsLoadingMore || _reviewsPage > _reviewsTotalPages) return;
      setState(() => _reviewsLoadingMore = true);
    }

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
        trailing: Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: onReject, child: const Text('Reject')),
            ElevatedButton(onPressed: onApprove, child: const Text('Approve')),
          ],
        ),
      ),
    );
  }

  Widget _buildPayouts() {
    if (_payoutsLoading) {
      return const Center(child: CircularProgressIndicator());
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
