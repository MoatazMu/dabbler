import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/data_retention_service.dart';
import '../../../../core/utils/logger.dart';

/// Data Retention Settings Screen for GDPR compliance
class DataRetentionSettingsScreen extends ConsumerStatefulWidget {
  final String userId;

  const DataRetentionSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<DataRetentionSettingsScreen> createState() => _DataRetentionSettingsScreenState();
}

class _DataRetentionSettingsScreenState extends ConsumerState<DataRetentionSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, Duration> _retentionPolicies = {};
  bool _autoCleanupEnabled = true;
  Duration _gracePeriod = Duration(days: 30);
  List<Map<String, dynamic>> _upcomingCleanups = [];

  @override
  void initState() {
    super.initState();
    _loadRetentionSettings();
  }

  Future<void> _loadRetentionSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataRetentionService = ref.read(dataRetentionServiceProvider);
      
      // Load current policy or use defaults
      final policy = await dataRetentionService.getUserRetentionPolicy(widget.userId);
      
      if (policy != null) {
        _retentionPolicies = Map.from(policy.policies);
        _autoCleanupEnabled = policy.autoCleanupEnabled;
        _gracePeriod = policy.gracePeriod;
      } else {
        _retentionPolicies = DataRetentionService.getDefaultRetentionPolicies();
      }

      // Load upcoming cleanups
      _upcomingCleanups = await dataRetentionService.getUpcomingCleanups(widget.userId);

    } catch (e) {
      Logger.error('Error loading retention settings', e);
      _showErrorMessage('Failed to load retention settings');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRetentionSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final dataRetentionService = ref.read(dataRetentionServiceProvider);
      
      await dataRetentionService.configureRetentionPolicy(
        userId: widget.userId,
        retentionPolicies: _retentionPolicies,
        enableAutoCleanup: _autoCleanupEnabled,
        gracePeriod: _gracePeriod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retention settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload to get updated upcoming cleanups
        await _loadRetentionSettings();
      }

    } catch (e) {
      Logger.error('Error saving retention settings', e);
      _showErrorMessage('Failed to save retention settings');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestGracePeriod(String dataType) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GracePeriodDialog(dataType: dataType),
    );

    if (result != null) {
      try {
        final dataRetentionService = ref.read(dataRetentionServiceProvider);
        await dataRetentionService.requestGracePeriod(
          userId: widget.userId,
          dataType: dataType,
          gracePeriod: result['duration'] as Duration,
          reason: result['reason'] as String?,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Grace period requested for ${_getDataTypeDisplayName(dataType)}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadRetentionSettings();
      } catch (e) {
        _showErrorMessage('Failed to request grace period');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Retention Settings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: const Text(
              'GDPR Compliance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRetentionPolicyCard(),
            const SizedBox(height: 24),
            _buildUpcomingCleanupsCard(),
            const SizedBox(height: 24),
            _buildAutomationSettingsCard(),
            const SizedBox(height: 24),
            _buildInformationCard(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveRetentionSettings,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save Settings'),
        ),
      ),
    );
  }

  Widget _buildRetentionPolicyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Data Retention Periods',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure how long different types of data are kept before automatic deletion.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            ..._retentionPolicies.entries.map((entry) => _buildRetentionPolicyItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionPolicyItem(String dataType, Duration duration) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getDataTypeIcon(dataType), color: _getDataTypeColor(dataType)),
        title: Text(_getDataTypeDisplayName(dataType)),
        subtitle: Text(_getDataTypeDescription(dataType)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: duration.inDays,
              items: _getRetentionOptions(dataType),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _retentionPolicies[dataType] = Duration(days: value);
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.schedule_send, size: 16),
              onPressed: () => _requestGracePeriod(dataType),
              tooltip: 'Request grace period',
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _getRetentionOptions(String dataType) {
    final options = <int>[];
    
    // Base options for all data types
    options.addAll([30, 90, 180, 365, 365 * 2, 365 * 3, 365 * 5, 365 * 7]);
    
    // Special options for specific data types
    switch (dataType) {
      case 'audit_logs':
        options.addAll([365 * 10]); // Up to 10 years for security logs
        break;
      case 'profile_data':
        options.addAll([365 * 10]); // Extended for profile data
        break;
    }

    options.sort();
    
    return options.map((days) => DropdownMenuItem<int>(
      value: days,
      child: Text(_formatDuration(Duration(days: days))),
    )).toList();
  }

  Widget _buildUpcomingCleanupsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Data Cleanups',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_upcomingCleanups.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'No upcoming cleanups scheduled',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ..._upcomingCleanups.map((cleanup) => _buildUpcomingCleanupItem(cleanup)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCleanupItem(Map<String, dynamic> cleanup) {
    final dataType = cleanup['data_type'] as String;
    final scheduledDate = DateTime.parse(cleanup['scheduled_cleanup_date']);
    final daysUntilCleanup = scheduledDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: daysUntilCleanup <= 7 ? Colors.red : Colors.orange,
          child: Icon(
            _getDataTypeIcon(dataType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(_getDataTypeDisplayName(dataType)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled: ${DateFormat('MMM dd, yyyy').format(scheduledDate)}'),
            Text('Days remaining: $daysUntilCleanup'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'grace_period') {
              _requestGracePeriod(dataType);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'grace_period',
              child: Row(
                children: [
                  Icon(Icons.schedule_send, size: 16),
                  SizedBox(width: 8),
                  Text('Request Grace Period'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_outlined, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Automation Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Enable Automatic Cleanup'),
              subtitle: const Text('Automatically delete data based on retention policies'),
              value: _autoCleanupEnabled,
              onChanged: (value) => setState(() => _autoCleanupEnabled = value),
            ),
            
            const Divider(),
            
            ListTile(
              title: const Text('Default Grace Period'),
              subtitle: const Text('Time before data deletion where you can request recovery'),
              trailing: DropdownButton<int>(
                value: _gracePeriod.inDays,
                items: [7, 14, 30, 60, 90].map((days) => DropdownMenuItem(
                  value: days,
                  child: Text('$days days'),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _gracePeriod = Duration(days: value));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Data Retention Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            const Text('Important Information:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            
            ...[
              'Data is automatically deleted based on your retention settings',
              'You will receive notifications before data deletion',
              'Grace periods can be requested to delay deletion',
              'Some data may be retained longer for legal compliance',
              'Critical security logs are kept for minimum required periods',
              'You can export your data before deletion using the Data Export feature',
            ].map((info) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(info)),
                ],
              ),
            )),
            
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showDataTypesHelp(),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Data Types Help'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _showRetentionHelp(),
                  icon: const Icon(Icons.policy),
                  label: const Text('Retention Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getDataTypeDisplayName(String dataType) {
    switch (dataType) {
      case 'profile_data':
        return 'Profile Data';
      case 'game_history':
        return 'Game History';
      case 'messages':
        return 'Messages';
      case 'audit_logs':
        return 'Security Logs';
      case 'login_history':
        return 'Login History';
      case 'media_files':
        return 'Media Files';
      case 'location_data':
        return 'Location Data';
      case 'analytics_data':
        return 'Analytics Data';
      default:
        return dataType.replaceAll('_', ' ').title();
    }
  }

  String _getDataTypeDescription(String dataType) {
    switch (dataType) {
      case 'profile_data':
        return 'Your profile information and settings';
      case 'game_history':
        return 'Records of games you\'ve played';
      case 'messages':
        return 'Chat messages and communications';
      case 'audit_logs':
        return 'Security and activity logs';
      case 'login_history':
        return 'Login attempts and session data';
      case 'media_files':
        return 'Photos and files you\'ve uploaded';
      case 'location_data':
        return 'Location information for game matching';
      case 'analytics_data':
        return 'Usage statistics and analytics';
      default:
        return 'Data of type: $dataType';
    }
  }

  IconData _getDataTypeIcon(String dataType) {
    switch (dataType) {
      case 'profile_data':
        return Icons.person;
      case 'game_history':
        return Icons.sports_esports;
      case 'messages':
        return Icons.message;
      case 'audit_logs':
        return Icons.security;
      case 'login_history':
        return Icons.login;
      case 'media_files':
        return Icons.photo;
      case 'location_data':
        return Icons.location_on;
      case 'analytics_data':
        return Icons.analytics;
      default:
        return Icons.data_object;
    }
  }

  Color _getDataTypeColor(String dataType) {
    switch (dataType) {
      case 'profile_data':
        return Colors.blue;
      case 'game_history':
        return Colors.green;
      case 'messages':
        return Colors.orange;
      case 'audit_logs':
        return Colors.red;
      case 'login_history':
        return Colors.purple;
      case 'media_files':
        return Colors.pink;
      case 'location_data':
        return Colors.teal;
      case 'analytics_data':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    if (days < 30) {
      return '$days days';
    } else if (days < 365) {
      final months = (days / 30).round();
      return '$months months';
    } else {
      final years = (days / 365).round();
      return '$years years';
    }
  }

  void _showDataTypesHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Types Explained'),
        content: const SingleChildScrollView(
          child: Text('''
Profile Data: Your personal information, preferences, and account settings.

Game History: Records of games you've participated in, including results and statistics.

Messages: All communications through the app, including chat messages.

Security Logs: Activity logs for security monitoring and fraud prevention.

Login History: Records of when and how you've accessed your account.

Media Files: Photos, videos, and other files you've uploaded.

Location Data: Approximate location information used for game matching.

Analytics Data: Usage statistics and app interaction data.
          '''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRetentionHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Retention Policy'),
        content: const SingleChildScrollView(
          child: Text('''
Our data retention policy ensures your data is kept only as long as necessary:

• Data is automatically deleted based on your preferences
• You receive notifications before any deletion
• Grace periods can be requested to delay deletion
• Some data may be kept longer for legal compliance
• Security logs have minimum retention requirements
• You can export your data before deletion

You have full control over your data retention preferences within legal limits.
          '''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Extension to capitalize strings
extension StringExtension on String {
  String title() {
    return split(' ').map((word) => 
      word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
    ).join(' ');
  }
}

/// Dialog for requesting grace period
class _GracePeriodDialog extends StatefulWidget {
  final String dataType;

  const _GracePeriodDialog({required this.dataType});

  @override
  State<_GracePeriodDialog> createState() => _GracePeriodDialogState();
}

class _GracePeriodDialogState extends State<_GracePeriodDialog> {
  Duration _selectedDuration = Duration(days: 30);
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Request Grace Period'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request a grace period for ${widget.dataType.replaceAll('_', ' ')} data deletion.'),
          const SizedBox(height: 16),
          
          const Text('Grace Period Duration:'),
          DropdownButton<Duration>(
            value: _selectedDuration,
            isExpanded: true,
            items: [
              Duration(days: 7),
              Duration(days: 14),
              Duration(days: 30),
              Duration(days: 60),
              Duration(days: 90),
            ].map((duration) => DropdownMenuItem(
              value: duration,
              child: Text('${duration.inDays} days'),
            )).toList(),
            onChanged: (value) => setState(() => _selectedDuration = value!),
          ),
          
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Why do you need this grace period?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'duration': _selectedDuration,
            'reason': _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
          }),
          child: const Text('Request'),
        ),
      ],
    );
  }
}
