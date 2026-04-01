import 'package:flutter/material.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/organizer/services/organizer_admin_service.dart';

class DisputeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dispute;
  const DisputeDetailScreen({super.key, required this.dispute});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final OrganizerAdminService _service = OrganizerAdminService();
  final TextEditingController _notesController = TextEditingController();
  String _status = 'in_review';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.dispute['status']?.toString() ?? 'open';
    _notesController.text = widget.dispute['resolutionNotes']?.toString() ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.updateDispute(
        int.parse(widget.dispute['id'].toString()),
        _status,
        resolutionNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dispute;
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Dispute ID', d['id']?.toString() ?? '-'),
            _infoRow('Status', d['status']?.toString() ?? '-'),
            _infoRow('Reason', d['reason']?.toString() ?? '-'),
            _infoRow('Booking Type', d['bookingType']?.toString() ?? '-'),
            _infoRow('Booking ID', d['bookingId']?.toString() ?? '-'),
            _infoRow('Payment ID', d['paymentId']?.toString() ?? '-'),
            const SizedBox(height: 16),
            Text('Details', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 6),
            Text(d['details']?.toString() ?? 'No details'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Update Status'),
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(value: 'in_review', child: Text('In Review')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (val) => setState(() => _status = val ?? 'in_review'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Resolution Notes'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
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
