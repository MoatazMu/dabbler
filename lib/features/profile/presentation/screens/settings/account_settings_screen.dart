import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data_export_screen.dart';
import '../data_retention_settings_screen.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _twoFactorEnabled = false;
  bool _isLoading = false;
  final String _currentUserId = 'user_123';
  final String _currentUserEmail = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _emailController.text = 'user@example.com';
    _phoneController.text = '+1 234 567 8900';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAccountInfoSection(),
          const SizedBox(height: 24),
          _buildSecuritySection(),
          const SizedBox(height: 24),
          _buildDataSection(),
          const SizedBox(height: 24),
          _buildDangerZoneSection(),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAccountInfo,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Update Information'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.security),
                title: const Text('Two-Factor Authentication'),
                subtitle: Text(_twoFactorEnabled 
                    ? 'Enhanced security enabled' 
                    : 'Add an extra layer of security'),
                value: _twoFactorEnabled,
                onChanged: _toggleTwoFactor,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('Manage Devices'),
                subtitle: const Text('View and manage signed-in devices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _manageDevices,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data & Privacy (GDPR)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your personal data in compliance with GDPR regulations',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined, color: Colors.blue),
                title: const Text('Export Your Data'),
                subtitle: const Text('Download a complete copy of your personal data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToDataExport,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.schedule_outlined, color: Colors.orange),
                title: const Text('Data Retention Settings'),
                subtitle: const Text('Control how long your data is kept'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToDataRetention,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: Colors.green),
                title: const Text('Privacy Settings'),
                subtitle: const Text('Control who can see your information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed('settings-privacy'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.policy_outlined, color: Colors.purple),
                title: const Text('Privacy Policy & Rights'),
                subtitle: const Text('Learn about your data rights under GDPR'),
                trailing: const Icon(Icons.open_in_new),
                onTap: _showGDPRRights,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.red[50],
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.pause_circle, color: Colors.orange),
                title: const Text('Deactivate Account'),
                subtitle: const Text('Temporarily disable your account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _deactivateAccount,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Account'),
                subtitle: const Text('Permanently delete your account and all data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateAccountInfo() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account information updated')),
      );
    }
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password functionality coming soon')),
    );
  }

  void _toggleTwoFactor(bool value) {
    setState(() => _twoFactorEnabled = value);
  }

  void _manageDevices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device management coming soon')),
    );
  }

  void _navigateToDataExport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataExportScreen(
          userId: _currentUserId,
          userEmail: _currentUserEmail,
        ),
      ),
    );
  }

  void _navigateToDataRetention() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataRetentionSettingsScreen(
          userId: _currentUserId,
        ),
      ),
    );
  }

  void _showGDPRRights() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your GDPR Rights'),
        content: const SingleChildScrollView(
          child: Text('''Under the General Data Protection Regulation (GDPR), you have the following rights:

• Right to Access - Request copies of your personal data
• Right to Rectification - Request correction of inaccurate data  
• Right to Erasure - Request deletion of your personal data
• Right to Restrict Processing - Limit how we use your data
• Right to Data Portability - Transfer your data to another service
• Right to Object - Object to certain data processing activities
• Right to Withdraw Consent - Withdraw consent at any time

To exercise these rights or for more information, contact our Data Protection Officer at privacy@dabbler.app

Full Privacy Policy: https://dabbler.app/privacy-policy'''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('View Policy'),
          ),
        ],
      ),
    );
  }

  void _deactivateAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text('Are you sure you want to deactivate your account? You can reactivate it anytime by signing in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
    }
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
