import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen for managing account settings like email, password, and security
class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isTwoFactorEnabled = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAccountData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadAccountData() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Load actual user data
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _emailController.text = 'user@example.com';
      _isTwoFactorEnabled = false;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmailSection(),
                      const SizedBox(height: 30),
                      _buildPasswordSection(),
                      const SizedBox(height: 30),
                      _buildSecuritySection(),
                      const SizedBox(height: 30),
                      _buildDangerZone(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Address',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateEmail,
              child: const Text('Update Email'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Add an extra layer of security to your account'),
              value: _isTwoFactorEnabled,
              onChanged: (value) {
                setState(() {
                  _isTwoFactorEnabled = value;
                });
                _toggleTwoFactor(value);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Manage Devices'),
              subtitle: const Text('View and manage logged-in devices'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _manageDevices,
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Login History'),
              subtitle: const Text('View recent login activity'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _viewLoginHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account and all data'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _updateEmail() {
    // TODO: Implement email update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email update functionality coming soon')),
    );
  }

  void _changePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement password change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change functionality coming soon')),
    );
  }

  void _toggleTwoFactor(bool enabled) {
    // TODO: Implement two-factor authentication toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled 
            ? 'Two-factor authentication enabled' 
            : 'Two-factor authentication disabled'
        ),
      ),
    );
  }

  void _manageDevices() {
    // TODO: Navigate to device management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device management coming soon')),
    );
  }

  void _viewLoginHistory() {
    // TODO: Navigate to login history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login history coming soon')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion functionality coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}