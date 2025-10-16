import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  // Account information
  final String _currentEmail = 'user@example.com';
  final String _currentPhone = '+1 (555) 123-4567';
  final bool _emailVerified = true;
  final bool _phoneVerified = false;

  // Two-factor authentication
  bool _twoFactorEnabled = false;
  final List<String> _backupCodes = [
    'ABCD-1234',
    'EFGH-5678',
    'IJKL-9012',
  ];

  // Linked accounts
  final Map<String, bool> _linkedAccounts = {
    'google': true,
    'apple': false,
    'facebook': false,
    'twitter': false,
  };

  // Security activities (mock data)
  final List<SecurityActivity> _recentActivities = [
    SecurityActivity(
      activity: 'Password changed',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      location: 'New York, NY',
      device: 'iPhone 14 Pro',
    ),
    SecurityActivity(
      activity: 'Login from new device',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      location: 'San Francisco, CA',
      device: 'MacBook Pro',
    ),
    SecurityActivity(
      activity: 'Account created',
      timestamp: DateTime.now().subtract(const Duration(days: 30)),
      location: 'New York, NY',
      device: 'iPhone 14 Pro',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildAccountInformationSection(context)),
              SliverToBoxAdapter(child: _buildSecuritySection(context)),
              SliverToBoxAdapter(child: _buildLinkedAccountsSection(context)),
              SliverToBoxAdapter(child: _buildDataSection(context)),
              SliverToBoxAdapter(child: _buildDangerZoneSection(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Account Management',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildAccountInformationSection(BuildContext context) {
    return _buildSection(
      context,
      'Account Information',
      'Manage your email, phone, and verification status',
      [
        _buildInfoItem(
          'Email Address',
          _currentEmail,
          Icons.email_outlined,
          isVerified: _emailVerified,
          onTap: _changeEmail,
          onVerify: _emailVerified ? null : _verifyEmail,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          'Phone Number',
          _currentPhone,
          Icons.phone_outlined,
          isVerified: _phoneVerified,
          onTap: _changePhone,
          onVerify: _phoneVerified ? null : _verifyPhone,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _changePassword,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Change Password'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String title,
    String value,
    IconData icon, {
    required bool isVerified,
    VoidCallback? onTap,
    VoidCallback? onVerify,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unverified',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onTap != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    child: const Text('Change'),
                  ),
                ),
              if (onTap != null && onVerify != null) const SizedBox(width: 12),
              if (onVerify != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onVerify,
                    child: const Text('Verify'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return _buildSection(
      context,
      'Security',
      'Manage your account security settings',
      [
        _buildSecurityToggle(
          'Two-Factor Authentication',
          _twoFactorEnabled 
              ? 'Extra security enabled with authenticator app'
              : 'Add an extra layer of security',
          Icons.security_outlined,
          _twoFactorEnabled,
          (value) => _toggleTwoFactor(value),
        ),
        if (_twoFactorEnabled) ...[
          const SizedBox(height: 16),
          _buildBackupCodesSection(context),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        _buildSecurityActivitiesSection(context),
      ],
    );
  }

  Widget _buildSecurityToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.grey[300]!,
        ),
        color: value ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: value ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? Theme.of(context).primaryColor : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCodesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Backup Codes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Save these codes in a secure place. You can use them to access your account if you lose your authenticator device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 12),
          ...(_backupCodes.take(2).map((code) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    code,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          })),
          if (_backupCodes.length > 2)
            Text(
              'and ${_backupCodes.length - 2} more...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: _viewAllBackupCodes,
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _regenerateBackupCodes,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityActivitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Security Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _viewAllActivity,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_recentActivities.take(3).map((activity) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getActivityColor(activity.activity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActivityIcon(activity.activity),
                    size: 16,
                    color: _getActivityColor(activity.activity),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.activity,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activity.device} • ${activity.location}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatActivityDate(activity.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        })),
      ],
    );
  }

  Widget _buildLinkedAccountsSection(BuildContext context) {
    return _buildSection(
      context,
      'Linked Accounts',
      'Connect your social accounts for easier sign-in',
      [
        ..._linkedAccounts.entries.map((entry) {
          final platform = entry.key;
          final isLinked = entry.value;
          final platformData = _getPlatformData(platform);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLinked 
                    ? (platformData['color'] as Color).withOpacity(0.3)
                    : Colors.grey[300]!,
              ),
              color: isLinked 
                  ? (platformData['color'] as Color).withOpacity(0.05)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (platformData['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    platformData['icon'],
                    size: 16,
                    color: platformData['color'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platformData['name'],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLinked ? 'Connected' : 'Not connected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLinked ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _toggleLinkedAccount(platform, !isLinked),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLinked ? Colors.grey[100] : platformData['color'],
                    foregroundColor: isLinked ? Colors.grey[700] : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(isLinked ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return _buildSection(
      context,
      'Data Management',
      'Download or manage your personal data',
      [
        _buildDataAction(
          'Export Account Data',
          'Download a copy of your account data',
          Icons.download_outlined,
          Colors.blue,
          _exportData,
        ),
        const SizedBox(height: 12),
        _buildDataAction(
          'Data Usage Report',
          'See how your data is being used',
          Icons.analytics_outlined,
          Colors.green,
          _viewDataUsage,
        ),
      ],
    );
  }

  Widget _buildDataAction(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            color: Colors.red.withOpacity(0.05),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_outlined, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'These actions are irreversible. Please proceed with caution.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red[800],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showDeleteAccountDialog,
                  icon: const Icon(Icons.delete_forever, size: 20),
                  label: const Text('Delete Account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String description, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getPlatformData(String platform) {
    switch (platform) {
      case 'google':
        return {'name': 'Google', 'icon': Icons.g_mobiledata, 'color': Colors.red};
      case 'apple':
        return {'name': 'Apple', 'icon': Icons.apple, 'color': Colors.black};
      case 'facebook':
        return {'name': 'Facebook', 'icon': Icons.facebook, 'color': Colors.blue};
      case 'twitter':
        return {'name': 'Twitter', 'icon': Icons.flutter_dash, 'color': Colors.lightBlue};
      default:
        return {'name': platform, 'icon': Icons.link, 'color': Colors.grey};
    }
  }

  IconData _getActivityIcon(String activity) {
    if (activity.contains('Password')) return Icons.lock_outline;
    if (activity.contains('Login')) return Icons.login;
    if (activity.contains('created')) return Icons.person_add_outlined;
    return Icons.security_outlined;
  }

  Color _getActivityColor(String activity) {
    if (activity.contains('Password')) return Colors.orange;
    if (activity.contains('Login')) return Colors.blue;
    if (activity.contains('created')) return Colors.green;
    return Colors.grey;
  }

  String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
  }

  void _changeEmail() {
    // Implement email change logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email change feature would be implemented here')),
    );
  }

  void _changePhone() {
    // Implement phone change logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone change feature would be implemented here')),
    );
  }

  void _verifyEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _verifyPhone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification SMS sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change feature would be implemented here')),
    );
  }

  void _toggleTwoFactor(bool value) {
    setState(() {
      _twoFactorEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Two-factor authentication enabled' : 'Two-factor authentication disabled'),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  void _viewAllBackupCodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _backupCodes.map((code) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(
                code,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _regenerateBackupCodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Backup Codes'),
        content: const Text('This will invalidate your current backup codes and generate new ones. Make sure to save the new codes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup codes regenerated'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _viewAllActivity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full activity log would be shown here')),
    );
  }

  void _toggleLinkedAccount(String platform, bool link) {
    setState(() {
      _linkedAccounts[platform] = link;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getPlatformData(platform)['name']} ${link ? 'connected' : 'disconnected'}'),
        backgroundColor: link ? Colors.green : Colors.orange,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export started. You\'ll receive an email when ready.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewDataUsage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data usage report would be shown here')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This action cannot be undone. Deleting your account will:'),
            SizedBox(height: 8),
            Text('• Remove all your profile information'),
            Text('• Delete your game history and statistics'),
            Text('• Cancel any upcoming games'),
            Text('• Remove you from all teams'),
            SizedBox(height: 16),
            Text('Are you absolutely sure you want to delete your account?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedWithAccountDeletion();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _proceedWithAccountDeletion() {
    // Show final confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text('Type "DELETE" to confirm account deletion:'),
        actions: [
          TextField(
            onSubmitted: (value) {
              if (value == 'DELETE') {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion initiated'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            decoration: const InputDecoration(
              hintText: 'Type "DELETE"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SecurityActivity {
  final String activity;
  final DateTime timestamp;
  final String location;
  final String device;

  SecurityActivity({
    required this.activity,
    required this.timestamp,
    required this.location,
    required this.device,
  });
}
