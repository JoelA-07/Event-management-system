import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/payments/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

class PaymentSummaryScreen extends StatefulWidget {
  final String bookingType;
  final int bookingId;

  const PaymentSummaryScreen({
    super.key,
    required this.bookingType,
    required this.bookingId,
  });

  @override
  State<PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen> {
  final PaymentService _service = PaymentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Map<String, dynamic>? _summary;
  bool _loading = true;
  String _role = 'customer';

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _payouts = [];
  int _txPage = 1;
  int _txTotalPages = 1;
  bool _txLoadingMore = false;
  bool _statusCheckDone = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      _txPage = 1;
      _transactions = [];
      _payouts = [];
      _loading = true;
    }

    final role = await _storage.read(key: 'role');
    final summary = await _service.fetchSummary(
      bookingType: widget.bookingType,
      bookingId: widget.bookingId,
      page: _txPage,
      limit: 20,
    );
    if (!mounted) return;

    final payment = summary?['payment'];
    final txBlock = summary?['transactions'];
    final payoutBlock = summary?['payouts'];

    List<Map<String, dynamic>> txItems = [];
    List<Map<String, dynamic>> payoutItems = [];
    int txTotalPages = 1;

    if (txBlock is Map && txBlock['data'] is List) {
      txItems = List<Map<String, dynamic>>.from(txBlock['data']);
      txTotalPages = txBlock['meta']?['totalPages'] ?? 1;
    } else if (txBlock is List) {
      txItems = List<Map<String, dynamic>>.from(txBlock);
    }

    if (payoutBlock is Map && payoutBlock['data'] is List) {
      payoutItems = List<Map<String, dynamic>>.from(payoutBlock['data']);
    } else if (payoutBlock is List) {
      payoutItems = List<Map<String, dynamic>>.from(payoutBlock);
    }

    setState(() {
      _role = role ?? 'customer';
      _summary = summary;
      _transactions = reset ? txItems : [..._transactions, ...txItems];
      _payouts = reset ? payoutItems : [..._payouts, ...payoutItems];
      _txTotalPages = txTotalPages;
      _txPage += 1;
      _loading = false;
      _txLoadingMore = false;
    });

    if (!_statusCheckDone && payment != null) {
      final status = payment['status']?.toString() ?? 'pending';
      final hasPendingOnlineTx = _transactions.any((t) =>
          t['method']?.toString() == 'online' &&
          t['status']?.toString() == 'pending' &&
          (t['razorpayPaymentLinkId']?.toString().isNotEmpty ?? false));
      if (status != 'paid' && hasPendingOnlineTx) {
        _statusCheckDone = true;
        final refreshed = await _service.refreshPaymentLinkStatus(paymentId: payment['id']);
        if (refreshed != null && mounted) {
          await _load(reset: true);
        }
      }
    }
  }

  Future<void> _loadMoreTx() async {
    if (_txLoadingMore || _txPage > _txTotalPages) return;
    setState(() => _txLoadingMore = true);
    await _load(reset: false);
  }

  double _num(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pay(String type) async {
    final url = await _service.createPaymentLink(
      bookingType: widget.bookingType,
      bookingId: widget.bookingId,
      type: type,
    );
    if (url == null || url.startsWith('http') == false) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(url ?? 'Failed to create payment link'), backgroundColor: Colors.red),
      );
      return;
    }
    await _openLink(url);
  }

  Future<void> _markCash() async {
    final amountController = TextEditingController();
    String paymentType = 'advance';
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Cash Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: paymentType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'advance', child: Text('Advance')),
                  DropdownMenuItem(value: 'balance', child: Text('Balance')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (value) => paymentType = value ?? 'advance',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (Rs)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final amount = double.parse(amountController.text);
    final message = await _service.markCash(
      bookingType: widget.bookingType,
      bookingId: widget.bookingId,
      amount: amount,
      type: paymentType,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? 'Cash recorded')));
    await _load(reset: true);
  }

  Future<void> _setPlan() async {
    if (_summary == null) return;
    final payment = Map<String, dynamic>.from(_summary!['payment']);
    final advanceController = TextEditingController(text: payment['advanceAmount']?.toString() ?? '0');
    final feeController = TextEditingController(text: payment['organizerFeePercent']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Payment Plan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: advanceController,
                decoration: const InputDecoration(labelText: 'Advance Amount (Rs)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount < 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: feeController,
                decoration: const InputDecoration(labelText: 'Organizer Fee % (optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final advance = double.parse(advanceController.text);
    final fee = double.tryParse(feeController.text);

    final message = await _service.updatePlan(
      paymentId: payment['id'],
      advanceAmount: advance,
      organizerFeePercent: fee,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? 'Plan updated')));
    await _load(reset: true);
  }

  Future<void> _recordPayout() async {
    if (_summary == null) return;
    final payment = Map<String, dynamic>.from(_summary!['payment']);
    final vendorId = payment['vendorId'];
    if (vendorId == null) return;

    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Vendor Payout'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (Rs)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final amount = double.parse(amountController.text);
    final message = await _service.recordPayout(
      paymentId: payment['id'],
      vendorId: vendorId,
      amount: amount,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? 'Payout recorded')));
    await _load(reset: true);
  }

  Future<void> _printReceipt() async {
    if (_summary == null) return;
    final payment = Map<String, dynamic>.from(_summary!['payment']);
    final bytes = await _service.fetchReceiptBytes(payment['id']);
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load receipt')),
      );
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payments')),
        body: const Center(child: Text('Unable to load payment details.')),
      );
    }

    final payment = Map<String, dynamic>.from(_summary!['payment']);

    final total = _num(payment['totalAmount']);
    final paid = _num(payment['paidAmount']);
    final advance = _num(payment['advanceAmount']);
    final remaining = (total - paid).clamp(0, total).toDouble();

    final isOrganizer = _role == 'organizer';
    final isCustomer = _role == 'customer';
    final isVendor = _role == 'photographer' || _role == 'caterer' || _role == 'designer' || _role == 'decorator' || _role == 'mehendi';

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summaryCard(total, advance, paid, remaining, payment['status']?.toString() ?? 'pending'),
            const SizedBox(height: 12),
            if (isCustomer) _customerActions(advance, remaining, paid),
            if (isOrganizer) _organizerActions(),
            if (isVendor) _vendorPayouts(_payouts),
            const SizedBox(height: 16),
            _transactionsList(),
            if (_txLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_txPage <= _txTotalPages)
              Center(
                child: TextButton(
                  onPressed: _loadMoreTx,
                  child: const Text('Load more transactions'),
                ),
              ),
            if ((payment['status'] ?? '') == 'paid')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: _printReceipt,
                  icon: const Icon(Icons.print),
                  label: const Text('Print Receipt'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(double total, double advance, double paid, double remaining, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${status.toUpperCase()}', style: TextStyle(color: status == 'paid' ? Colors.green : AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total: Rs $total'),
          Text('Advance: Rs $advance'),
          Text('Paid: Rs $paid'),
          Text('Remaining: Rs $remaining'),
        ],
      ),
    );
  }

  Widget _customerActions(double advance, double remaining, double paid) {
    final advanceDue = advance > 0 && paid < advance;
    final balanceDue = remaining > 0 && !advanceDue;
    final payment = _summary?['payment'];
    final hasPendingOnlineTx = _transactions.any((t) =>
        t['method']?.toString() == 'online' &&
        t['status']?.toString() == 'pending' &&
        (t['razorpayPaymentLinkId']?.toString().isNotEmpty ?? false));
    return Column(
      children: [
        if (advanceDue)
          ElevatedButton(
            onPressed: () => _pay('advance'),
            child: const Text('Pay Advance'),
          ),
        if (balanceDue)
          ElevatedButton(
            onPressed: () => _pay('balance'),
            child: const Text('Pay Remaining Balance'),
          ),
        if (hasPendingOnlineTx)
          TextButton(
            onPressed: () async {
              if (payment == null) return;
              await _service.refreshPaymentLinkStatus(paymentId: payment['id']);
              if (!mounted) return;
              await _load(reset: true);
            },
            child: const Text('Check Payment Status'),
          ),
      ],
    );
  }

  Widget _organizerActions() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _setPlan,
          icon: const Icon(Icons.tune),
          label: const Text('Set Payment Plan'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _markCash,
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Record Cash Payment'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _recordPayout,
          icon: const Icon(Icons.handshake),
          label: const Text('Record Vendor Payout'),
        ),
      ],
    );
  }

  Widget _transactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_transactions.isEmpty)
          const Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
        ..._transactions.map((t) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${t['type']} - Rs ${t['amount']}'),
              subtitle: Text('${t['method']}  ${t['status']}'),
              trailing: Text(t['paidAt']?.toString() ?? ''),
            ),
          );
        }),
      ],
    );
  }

  Widget _vendorPayouts(List<Map<String, dynamic>> payouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (payouts.isEmpty)
          const Text('No payouts yet.', style: TextStyle(color: Colors.grey)),
        ...payouts.map((p) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('Rs ${p['amount']}'),
              subtitle: Text('Status: ${p['status']}'),
              trailing: Text(p['paidAt']?.toString() ?? ''),
            ),
          );
        }),
      ],
    );
  }
}
