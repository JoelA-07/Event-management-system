import 'package:flutter/material.dart';
import 'package:mobile/features/settings/services/settings_service.dart';
import 'package:mobile/features/settings/services/user_settings_api_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/bookings/screens/my_booking_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SettingsService _settingsService = SettingsService();
  final UserSettingsApiService _settingsApi = UserSettingsApiService();

  String _name = "User";
  String _role = "customer";
  String? _email;
  String? _phone;

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
    setState(() => _isLoading = true);

    final profile = await _settingsApi.fetchProfile();
    if (profile != null) {
      _name = (profile['name']?.toString().trim().isNotEmpty ?? false)
          ? profile['name'].toString()
          : "User";
      _role = profile['role']?.toString() ?? "customer";
      _email = profile['email']?.toString();
      _phone = profile['phone']?.toString();

      await _settingsService.writeValue("name", _name);
      if (_email != null) {
        await _settingsService.writeValue("email", _email!);
      }
      await _settingsService.writeValue("role", _role);
      if (_phone != null) {
        await _settingsService.writeValue("phone", _phone!);
      }
    } else {
      final name = await _settingsService.readValue("name");
      final role = await _settingsService.readValue("role");
      final email = await _settingsService.readValue("email");
      final phone = await _settingsService.readValue("phone");

      _name = (name == null || name.isEmpty) ? "User" : name;
      _role = role ?? "customer";
      _email = email;
      _phone = phone;
    }

    final settings = await _settingsApi.fetchSettings();
    if (settings != null) {
      _bookingAlerts = settings['bookingAlerts'] ?? true;
      _paymentAlerts = settings['paymentAlerts'] ?? true;
      _promoAlerts = settings['promoAlerts'] ?? false;
      _profileVisible = settings['profileVisible'] ?? true;
      _analyticsEnabled = settings['analyticsEnabled'] ?? true;

      await _settingsService.writeBool(SettingsService.bookingAlertsKey, _bookingAlerts);
      await _settingsService.writeBool(SettingsService.paymentAlertsKey, _paymentAlerts);
      await _settingsService.writeBool(SettingsService.promoAlertsKey, _promoAlerts);
      await _settingsService.writeBool(SettingsService.profileVisibleKey, _profileVisible);
      await _settingsService.writeBool(SettingsService.analyticsKey, _analyticsEnabled);
    } else {
      _bookingAlerts = await _settingsService.readBool(
        SettingsService.bookingAlertsKey,
        defaultValue: true,
      );
      _paymentAlerts = await _settingsService.readBool(
        SettingsService.paymentAlertsKey,
        defaultValue: true,
      );
      _promoAlerts = await _settingsService.readBool(
        SettingsService.promoAlertsKey,
        defaultValue: false,
      );
      _profileVisible = await _settingsService.readBool(
        SettingsService.profileVisibleKey,
        defaultValue: true,
      );
      _analyticsEnabled = await _settingsService.readBool(
        SettingsService.analyticsKey,
        defaultValue: true,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<bool> _updateSwitch(String key, bool value) async {
    final fieldMap = {
      SettingsService.bookingAlertsKey: 'bookingAlerts',
      SettingsService.paymentAlertsKey: 'paymentAlerts',
      SettingsService.promoAlertsKey: 'promoAlerts',
      SettingsService.profileVisibleKey: 'profileVisible',
      SettingsService.analyticsKey: 'analyticsEnabled',
    };

    final apiField = fieldMap[key];
    if (apiField == null) return false;

    final updates = {apiField: value};
    final result = await _settingsApi.updateSettings(updates);
    if (result == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not update setting"), backgroundColor: Colors.red),
      );
      return false;
    }

    await _settingsService.writeBool(key, value);
    return true;
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

  Future<void> _openEditProfile() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email ?? "");
    final phoneController = TextEditingController(text: _phone ?? "");
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text("Edit Profile"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Full Name"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Name is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone (optional)"),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setStateDialog(() => isSaving = true);
                        final updated = await _settingsApi.updateProfile(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim().isEmpty
                              ? null
                              : phoneController.text.trim(),
                        );
                        setStateDialog(() => isSaving = false);

                        if (updated == null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update profile"), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        if (!mounted) return;
                        Navigator.pop(context, true);
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
              ),
            ],
          ),
        );
      },
    );

    if (shouldRefresh == true) {
      await _loadProfileAndSettings();
    }
  }

  Future<void> _openChangePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text("Change Password"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    decoration: const InputDecoration(labelText: "Current Password"),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Current password is required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: newController,
                    decoration: const InputDecoration(labelText: "New Password"),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return "Use at least 8 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmController,
                    decoration: const InputDecoration(labelText: "Confirm New Password"),
                    obscureText: true,
                    validator: (value) {
                      if (value != newController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setStateDialog(() => isSaving = true);
                        final message = await _settingsApi.changePassword(
                          currentPassword: currentController.text,
                          newPassword: newController.text,
                        );
                        setStateDialog(() => isSaving = false);
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message ?? "Password updated")),
                        );
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Update"),
              ),
            ],
          ),
        );
      },
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
                    onChanged: (value) async {
                      final previous = _bookingAlerts;
                      setState(() => _bookingAlerts = value);
                      final ok = await _updateSwitch(SettingsService.bookingAlertsKey, value);
                      if (!ok && mounted) {
                        setState(() => _bookingAlerts = previous);
                      }
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.payments_outlined,
                    title: "Payment Alerts",
                    subtitle: "Get payment success/failure and refund updates",
                    value: _paymentAlerts,
                    onChanged: (value) async {
                      final previous = _paymentAlerts;
                      setState(() => _paymentAlerts = value);
                      final ok = await _updateSwitch(SettingsService.paymentAlertsKey, value);
                      if (!ok && mounted) {
                        setState(() => _paymentAlerts = previous);
                      }
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.local_offer_outlined,
                    title: "Offers and Promotions",
                    subtitle: "Get discount and package offer notifications",
                    value: _promoAlerts,
                    onChanged: (value) async {
                      final previous = _promoAlerts;
                      setState(() => _promoAlerts = value);
                      final ok = await _updateSwitch(SettingsService.promoAlertsKey, value);
                      if (!ok && mounted) {
                        setState(() => _promoAlerts = previous);
                      }
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.visibility_outlined,
                    title: "Profile Visibility",
                    subtitle: "Allow organizers/vendors to view your public profile",
                    value: _profileVisible,
                    onChanged: (value) async {
                      final previous = _profileVisible;
                      setState(() => _profileVisible = value);
                      final ok = await _updateSwitch(SettingsService.profileVisibleKey, value);
                      if (!ok && mounted) {
                        setState(() => _profileVisible = previous);
                      }
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.analytics_outlined,
                    title: "Analytics Sharing",
                    subtitle: "Share anonymous usage data to improve app quality",
                    value: _analyticsEnabled,
                    onChanged: (value) async {
                      final previous = _analyticsEnabled;
                      setState(() => _analyticsEnabled = value);
                      final ok = await _updateSwitch(SettingsService.analyticsKey, value);
                      if (!ok && mounted) {
                        setState(() => _analyticsEnabled = previous);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle("Account and Security"),
                  _buildActionTile(
                    icon: Icons.person_outline,
                    title: "Edit Profile",
                    subtitle: "Update your name, email, and phone",
                    onTap: _openEditProfile,
                  ),
                  _buildActionTile(
                    icon: Icons.lock_outline,
                    title: "Change Password",
                    subtitle: "Update your account password",
                    onTap: _openChangePassword,
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
                if (_phone != null && _phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _phone!,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
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
