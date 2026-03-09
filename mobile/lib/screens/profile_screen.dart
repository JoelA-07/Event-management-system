import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../utils/theme.dart';
import 'my_booking_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SettingsService _settingsService = SettingsService();

  String _name = "User";
  String _role = "customer";
  String? _email;

  bool _isLoading = true;
  bool _bookingAlerts = true;
  bool _paymentAlerts = true;
  bool _promoAlerts = false;
  bool _profileVisible = true;
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndSettings();
  }

  Future<void> _loadProfileAndSettings() async {
    final name = await _settingsService.readValue("name");
    final role = await _settingsService.readValue("role");
    final email = await _settingsService.readValue("email");

    final bookingAlerts = await _settingsService.readBool(
      SettingsService.bookingAlertsKey,
      defaultValue: true,
    );
    final paymentAlerts = await _settingsService.readBool(
      SettingsService.paymentAlertsKey,
      defaultValue: true,
    );
    final promoAlerts = await _settingsService.readBool(
      SettingsService.promoAlertsKey,
      defaultValue: false,
    );
    final profileVisible = await _settingsService.readBool(
      SettingsService.profileVisibleKey,
      defaultValue: true,
    );
    final analyticsEnabled = await _settingsService.readBool(
      SettingsService.analyticsKey,
      defaultValue: true,
    );

    if (!mounted) return;
    setState(() {
      _name = (name == null || name.isEmpty) ? "User" : name;
      _role = role ?? "customer";
      _email = email;
      _bookingAlerts = bookingAlerts;
      _paymentAlerts = paymentAlerts;
      _promoAlerts = promoAlerts;
      _profileVisible = profileVisible;
      _analyticsEnabled = analyticsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _updateSwitch(String key, bool value) async {
    await _settingsService.writeBool(key, value);
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout from this device?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout")),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await _settingsService.clearAllLocalData();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Future<void> _resetPreferences() async {
    await _settingsService.clearSettingsOnly();
    if (!mounted) return;
    await _loadProfileAndSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preferences reset to default"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileAndSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAccountCard(),
                  const SizedBox(height: 16),
                  _buildSectionTitle("Essential Settings"),
                  _buildSwitchTile(
                    icon: Icons.event_note,
                    title: "Booking Updates",
                    subtitle: "Get alerts for booking confirmation and status changes",
                    value: _bookingAlerts,
                    onChanged: (value) {
                      setState(() => _bookingAlerts = value);
                      _updateSwitch(SettingsService.bookingAlertsKey, value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.payments_outlined,
                    title: "Payment Alerts",
                    subtitle: "Get payment success/failure and refund updates",
                    value: _paymentAlerts,
                    onChanged: (value) {
                      setState(() => _paymentAlerts = value);
                      _updateSwitch(SettingsService.paymentAlertsKey, value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.local_offer_outlined,
                    title: "Offers and Promotions",
                    subtitle: "Get discount and package offer notifications",
                    value: _promoAlerts,
                    onChanged: (value) {
                      setState(() => _promoAlerts = value);
                      _updateSwitch(SettingsService.promoAlertsKey, value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.visibility_outlined,
                    title: "Profile Visibility",
                    subtitle: "Allow organizers/vendors to view your public profile",
                    value: _profileVisible,
                    onChanged: (value) {
                      setState(() => _profileVisible = value);
                      _updateSwitch(SettingsService.profileVisibleKey, value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.analytics_outlined,
                    title: "Analytics Sharing",
                    subtitle: "Share anonymous usage data to improve app quality",
                    value: _analyticsEnabled,
                    onChanged: (value) {
                      setState(() => _analyticsEnabled = value);
                      _updateSwitch(SettingsService.analyticsKey, value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle("Account and Support"),
                  _buildActionTile(
                    icon: Icons.history,
                    title: "My Bookings",
                    subtitle: "View your booking history and statuses",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.policy_outlined,
                    title: "Privacy and Security",
                    subtitle: "Understand data use and account protection",
                    onTap: () => _showInfoDialog(
                      "Privacy and Security",
                      "Your login token is securely stored on device. "
                          "You can control profile visibility and analytics sharing from this page.",
                    ),
                  ),
                  _buildActionTile(
                    icon: Icons.support_agent,
                    title: "Help and Support",
                    subtitle: "Contact support for bookings and payments",
                    onTap: () => _showInfoDialog(
                      "Help and Support",
                      "Support email: support@eliteevents.app\n"
                          "For urgent booking help, contact your assigned vendor in booking details.",
                    ),
                  ),
                  _buildActionTile(
                    icon: Icons.info_outline,
                    title: "About",
                    subtitle: "App version and platform details",
                    onTap: () => _showInfoDialog(
                      "About Elite Events",
                      "Version 1.0.0\n"
                          "Manage halls, vendors, bookings, event discovery and payments in one place.",
                    ),
                  ),
                  const Divider(height: 28),
                  _buildActionTile(
                    icon: Icons.restart_alt,
                    title: "Reset Preferences",
                    subtitle: "Restore all setting toggles to default",
                    onTap: _resetPreferences,
                  ),
                  _buildActionTile(
                    icon: Icons.logout,
                    title: "Logout",
                    subtitle: "Sign out from this device",
                    onTap: _handleLogout,
                    destructive: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  _email ?? "Email not available",
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  _role.toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? Colors.red : AppTheme.primaryColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: destructive ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }
}
