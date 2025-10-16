import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Screen for exporting user data (GDPR compliance)
class ProfileDataExportScreen extends ConsumerStatefulWidget {
  const ProfileDataExportScreen({super.key});

  @override
  ConsumerState<ProfileDataExportScreen> createState() => _ProfileDataExportScreenState();
}

class _ProfileDataExportScreenState extends ConsumerState<ProfileDataExportScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isGenerating = false;
  bool _isDownloading = false;
  DateTime? _lastExportDate;
  String? _exportStatus;
  
  final Map<String, bool> _selectedDataTypes = {
    'profile': true,
    'games': true,
    'achievements': true,
    'statistics': true,
    'friends': true,
    'preferences': true,
    'notifications': false,
    'messages': false,
    'location': false,
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExportHistory();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  Future<void> _loadExportHistory() async {
    // TODO: Load from actual user data
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _lastExportDate = DateTime.now().subtract(const Duration(days: 45));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export My Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoHeader(),
                const SizedBox(height: 24),
                _buildDataSelectionCard(),
                const SizedBox(height: 24),
                _buildExportOptionsCard(),
                const SizedBox(height: 24),
                _buildExportHistoryCard(),
                const SizedBox(height: 24),
                _buildPrivacyNoticeCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildInfoHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data Export',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Export your data from Dabbler to keep a copy or transfer to another service. We believe you should have full control over your data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Data to Export',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which types of data you want to include in your export',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ..._selectedDataTypes.entries.map((entry) => 
              _buildDataTypeItem(entry.key, entry.value)
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.select_all, size: 18),
                  label: const Text('Select All'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.deselect, size: 18),
                  label: const Text('Deselect All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeItem(String dataType, bool isSelected) {
    final info = _getDataTypeInfo(dataType);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            _selectedDataTypes[dataType] = value ?? false;
          });
        },
        title: Text(
          info['title'],
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          info['description'],
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        secondary: Icon(
          info['icon'],
          color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Map<String, dynamic> _getDataTypeInfo(String dataType) {
    switch (dataType) {
      case 'profile':
        return {
          'title': 'Profile Information',
          'description': 'Name, email, bio, avatar, and basic profile details',
          'icon': Icons.person_outline,
        };
      case 'games':
        return {
          'title': 'Game History',
          'description': 'All games you\'ve created, joined, or participated in',
          'icon': Icons.sports_esports_outlined,
        };
      case 'achievements':
        return {
          'title': 'Achievements & Badges',
          'description': 'All unlocked achievements and skill badges',
          'icon': Icons.emoji_events_outlined,
        };
      case 'statistics':
        return {
          'title': 'Performance Statistics',
          'description': 'Game stats, win rates, and performance metrics',
          'icon': Icons.analytics_outlined,
        };
      case 'friends':
        return {
          'title': 'Social Connections',
          'description': 'Friends list and social connections',
          'icon': Icons.people_outline,
        };
      case 'preferences':
        return {
          'title': 'App Preferences',
          'description': 'Settings, preferences, and app configuration',
          'icon': Icons.settings_outlined,
        };
      case 'notifications':
        return {
          'title': 'Notification History',
          'description': 'Past notifications and communication preferences',
          'icon': Icons.notifications_outlined,
        };
      case 'messages':
        return {
          'title': 'Messages & Communication',
          'description': 'Chat messages and communication history',
          'icon': Icons.message_outlined,
        };
      case 'location':
        return {
          'title': 'Location Data',
          'description': 'Venue check-ins and location history',
          'icon': Icons.location_on_outlined,
        };
      default:
        return {
          'title': 'Unknown Data',
          'description': 'Description not available',
          'icon': Icons.help_outline,
        };
    }
  }

  Widget _buildExportOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExportFormatOption(
              'JSON Format',
              'Machine-readable format, suitable for developers',
              Icons.code,
              true,
            ),
            const Divider(),
            _buildExportFormatOption(
              'PDF Report',
              'Human-readable summary of your data',
              Icons.picture_as_pdf,
              false,
            ),
            const Divider(),
            _buildExportFormatOption(
              'CSV Data',
              'Spreadsheet format for statistical data',
              Icons.table_chart,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportFormatOption(
    String title,
    String description,
    IconData icon,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(description),
      trailing: isSelected 
        ? Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          )
        : const Icon(Icons.radio_button_unchecked),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildExportHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_lastExportDate != null) ...[
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Last Export'),
                subtitle: Text(_formatDate(_lastExportDate!)),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _downloadLastExport,
                  tooltip: 'Download last export',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No previous exports',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNoticeCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy Notice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Your exported data will be securely packaged and encrypted\n'
              '• Export files are temporarily stored and automatically deleted after 7 days\n'
              '• You can request up to 3 exports per month\n'
              '• Exported data includes only information associated with your account\n'
              '• Processing may take up to 30 days for large data sets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final selectedCount = _selectedDataTypes.values.where((selected) => selected).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isGenerating) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              _exportStatus ?? 'Preparing your data export...',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_isGenerating || _isDownloading || selectedCount == 0) 
                ? null 
                : _generateExport,
              icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
              label: Text(
                _isGenerating 
                  ? 'Generating...' 
                  : 'Generate Export ($selectedCount items)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAll() {
    setState(() {
      _selectedDataTypes.updateAll((key, value) => true);
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedDataTypes.updateAll((key, value) => false);
    });
  }

  Future<void> _generateExport() async {
    setState(() {
      _isGenerating = true;
      _exportStatus = 'Collecting your data...';
    });

    try {
      // Simulate data collection process
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _exportStatus = 'Processing profile information...';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _exportStatus = 'Compiling game history...';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _exportStatus = 'Generating export file...';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _exportStatus = 'Finalizing...';
      });
      
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Implement actual data export generation
      
      setState(() {
        _isGenerating = false;
        _exportStatus = null;
        _lastExportDate = DateTime.now();
      });

      if (mounted) {
        _showExportCompleteDialog();
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _exportStatus = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Complete'),
        content: const Text(
          'Your data export has been generated successfully. You can download it now or access it later from the export history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadLastExport();
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadLastExport() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // TODO: Implement actual download functionality
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate sharing the file
      await Share.share(
        'Your Dabbler data export is ready! This would normally be a download link.',
        subject: 'Dabbler Data Export',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export download started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}