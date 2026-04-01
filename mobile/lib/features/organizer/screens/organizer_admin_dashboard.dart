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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.fetchApprovals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? {};
        final halls = List<dynamic>.from(data['halls'] ?? []);
        final services = List<dynamic>.from(data['services'] ?? []);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Pending Halls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (halls.isEmpty) const Text('No pending halls.', style: TextStyle(color: Colors.grey)),
            ...halls.map((hall) => _approvalCard(
                  title: hall['name'] ?? 'Hall',
                  subtitle: hall['location'] ?? '',
                  onApprove: () async {
                    await _service.updateHallApproval(hall['id'], 'approved');
                    if (mounted) setState(() {});
                  },
                  onReject: () => _showReasonDialog(context, (reason) async {
                    await _service.updateHallApproval(hall['id'], 'rejected', reason: reason);
                    if (mounted) setState(() {});
                  }),
                )),
            const SizedBox(height: 24),
            const Text('Pending Vendor Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (services.isEmpty) const Text('No pending services.', style: TextStyle(color: Colors.grey)),
            ...services.map((service) => _approvalCard(
                  title: service['name'] ?? 'Service',
                  subtitle: service['category'] ?? '',
                  onApprove: () async {
                    await _service.updateServiceApproval(service['id'], 'approved');
                    if (mounted) setState(() {});
                  },
                  onReject: () => _showReasonDialog(context, (reason) async {
                    await _service.updateServiceApproval(service['id'], 'rejected', reason: reason);
                    if (mounted) setState(() {});
                  }),
                )),
          ],
        );
      },
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.fetchPayouts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? {};
        final payments = List<dynamic>.from(data['payments'] ?? []);
        final payouts = List<dynamic>.from(data['payouts'] ?? []);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (payments.isEmpty) const Text('No payments yet.', style: TextStyle(color: Colors.grey)),
            ...payments.take(20).map((p) => _simpleRow(
                  title: 'Payment #${p['id']}',
                  subtitle: 'Status: ${p['status']} | Paid: Rs ${p['paidAmount']}',
                )),
            const SizedBox(height: 24),
            const Text('Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (payouts.isEmpty) const Text('No payouts yet.', style: TextStyle(color: Colors.grey)),
            ...payouts.take(20).map((p) => _simpleRow(
                  title: 'Payout #${p['id']}',
                  subtitle: 'Vendor: ${p['vendorId']} | Amount: Rs ${p['amount']}',
                )),
          ],
        );
      },
    );
  }

  Widget _buildDisputes() {
    return FutureBuilder<List<dynamic>>(
      future: _service.fetchDisputes(status: 'open'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final disputes = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Open Disputes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (disputes.isEmpty) const Text('No open disputes.', style: TextStyle(color: Colors.grey)),
            ...disputes.map((d) => Card(
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
                      if (refreshed == true && mounted) setState(() {});
                    },
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildReviews() {
    return FutureBuilder<List<dynamic>>(
      future: _service.fetchReviewReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Reported Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (reports.isEmpty) const Text('No reported reviews.', style: TextStyle(color: Colors.grey)),
            ...reports.map((r) => Card(
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
                      if (refreshed == true && mounted) setState(() {});
                    },
                  ),
                )),
          ],
        );
      },
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
