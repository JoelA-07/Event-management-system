import 'package:flutter/material.dart';
import 'package:mobile/features/organizer/services/organizer_admin_service.dart';

class ReviewDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  const ReviewDetailScreen({super.key, required this.report});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final OrganizerAdminService _service = OrganizerAdminService();
  Map<String, dynamic>? _review;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reviewId = widget.report['reviewId'] as int?;
    if (reviewId == null) {
      setState(() => _loading = false);
      return;
    }

    final hallId = widget.report['hallId'] as int?;
    final serviceId = widget.report['serviceId'] as int?;

    final review = await _service.fetchReviewDetails(reviewId, hallId: hallId, serviceId: serviceId);
    if (!mounted) return;
    setState(() {
      _review = review ?? {};
      _loading = false;
    });
  }

  Future<void> _approve() async {
    final reviewId = widget.report['reviewId'] as int?;
    if (reviewId == null) return;
    await _service.moderateReview(reviewId, 'approved');
    await _service.resolveReviewReport(widget.report['id']);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _reject() async {
    final reviewId = widget.report['reviewId'] as int?;
    if (reviewId == null) return;
    await _service.moderateReview(reviewId, 'rejected');
    await _service.resolveReviewReport(widget.report['id']);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _infoRow('Report ID', widget.report['id']?.toString() ?? '-'),
                  _infoRow('Reason', widget.report['reason']?.toString() ?? '-'),
                  _infoRow('Details', widget.report['details']?.toString() ?? '-'),
                  const SizedBox(height: 16),
                  const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if ((_review?.isEmpty ?? true))
                    const Text('Review details unavailable.'),
                  if ((_review?.isNotEmpty ?? false)) ...[
                    _infoRow('Rating', _review?['rating']?.toString() ?? '-'),
                    _infoRow('Comment', _review?['comment']?.toString() ?? '-'),
                    _infoRow('Status', _review?['status']?.toString() ?? '-'),
                    if (_review?['User'] != null)
                      _infoRow('User', _review?['User']?['name']?.toString() ?? '-'),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reject,
                          child: const Text('Reject Review'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _approve,
                          child: const Text('Approve Review'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
