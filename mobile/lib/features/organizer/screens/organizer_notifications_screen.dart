import 'package:flutter/material.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/organizer/services/organizer_notification_service.dart';

class OrganizerNotificationsScreen extends StatefulWidget {
  const OrganizerNotificationsScreen({super.key});

  @override
  State<OrganizerNotificationsScreen> createState() => _OrganizerNotificationsScreenState();
}

class _OrganizerNotificationsScreenState extends State<OrganizerNotificationsScreen> {
  final OrganizerNotificationService _service = OrganizerNotificationService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isBroadcast = true;
  bool _isSending = false;
  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];
  String? _selectedEmail;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _typeController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _service.searchUsers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
      if (results.isEmpty) {
        _selectedEmail = null;
      }
    });
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    String? message;
    if (_isBroadcast) {
      message = await _service.sendBroadcast(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _typeController.text.trim(),
      );
    } else {
      final email = _emailController.text.trim();
      message = await _service.sendToEmail(
        email: email,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _typeController.text.trim(),
      );
    }

    setState(() => _isSending = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Notification sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notifications'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeToggle(),
              const SizedBox(height: 16),
              if (!_isBroadcast) _buildRecipientSection(),
              if (!_isBroadcast) const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Notification title',
                validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _bodyController,
                label: 'Message',
                hint: 'Write a short message',
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _typeController,
                label: 'Type (optional)',
                hint: 'example: booking_alert',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendNotification,
                  child: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isBroadcast ? 'Send Broadcast' : 'Send Notification'),
                ),
              ),
              const SizedBox(height: 14),
              _buildHelperCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recipient', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _searchController,
                  label: 'Search',
                  hint: 'Name or email',
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _searchUsers,
                  child: _isSearching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Search'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_searchResults.isNotEmpty) _buildDropdown(),
          if (_searchResults.isNotEmpty) const SizedBox(height: 10),
          _buildTextField(
            controller: _emailController,
            label: 'Target Email',
            hint: 'user@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (_isBroadcast) return null;
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedEmail,
      decoration: const InputDecoration(labelText: 'Select user'),
      items: _searchResults.map((user) {
        final email = (user['email'] ?? '').toString();
        final name = (user['name'] ?? '').toString();
        final role = (user['role'] ?? '').toString();
        return DropdownMenuItem<String>(
          value: email,
          child: Text('$name ($email) - $role'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedEmail = value;
          if (value != null) {
            _emailController.text = value;
          }
        });
      },
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Target', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _modeChip('Broadcast', _isBroadcast, () => setState(() => _isBroadcast = true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeChip('Particular User', !_isBroadcast, () => setState(() => _isBroadcast = false)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }

  Widget _buildHelperCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Tips', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text(
            'Broadcast sends to all subscribed users. For a specific user, search by name/email and select from the dropdown.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
