import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Push notification settings
  bool _pushNotificationsEnabled = true;
  bool _gameInvites = true;
  bool _messages = true;
  bool _reminders = true;
  bool _updates = false;
  bool _socialActivity = true;

  // Email notification settings
  bool _emailNotificationsEnabled = true;
  bool _emailGameInvites = false;
  bool _emailMessages = false;
  bool _emailReminders = true;
  bool _emailUpdates = true;
  bool _emailNewsletter = false;

  // SMS settings
  bool _smsNotificationsEnabled = false;
  bool _smsGameInvites = false;
  bool _smsReminders = false;

  // Quiet hours
  bool _quietHoursEnabled = true;
  TimeOfDay _quietStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEndTime = const TimeOfDay(hour: 8, minute: 0);

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
              SliverToBoxAdapter(child: _buildPushNotificationsSection(context)),
              SliverToBoxAdapter(child: _buildEmailNotificationsSection(context)),
              SliverToBoxAdapter(child: _buildSmsNotificationsSection(context)),
              SliverToBoxAdapter(child: _buildQuietHoursSection(context)),
              SliverToBoxAdapter(child: _buildTestNotificationSection(context)),
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
          'Notifications',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
      actions: [
        TextButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPushNotificationsSection(BuildContext context) {
    return _buildSection(
      context,
      'Push Notifications',
      'Get notified instantly on your device',
      [
        _buildMasterToggle(
          'Push Notifications',
          'Enable all push notifications',
          _pushNotificationsEnabled,
          (value) => setState(() => _pushNotificationsEnabled = value),
        ),
        if (_pushNotificationsEnabled) ...[
          const SizedBox(height: 16),
          _buildNotificationCategory(
            'Game Invites',
            'Invitations to join games',
            Icons.sports_esports_outlined,
            _gameInvites,
            (value) => setState(() => _gameInvites = value),
          ),
          _buildNotificationCategory(
            'Messages',
            'Direct messages and team chats',
            Icons.message_outlined,
            _messages,
            (value) => setState(() => _messages = value),
          ),
          _buildNotificationCategory(
            'Reminders',
            'Game reminders and schedule updates',
            Icons.schedule_outlined,
            _reminders,
            (value) => setState(() => _reminders = value),
          ),
          _buildNotificationCategory(
            'Social Activity',
            'Friend requests and social updates',
            Icons.people_outline,
            _socialActivity,
            (value) => setState(() => _socialActivity = value),
          ),
          _buildNotificationCategory(
            'App Updates',
            'New features and important updates',
            Icons.system_update_outlined,
            _updates,
            (value) => setState(() => _updates = value),
          ),
        ],
      ],
    );
  }

  Widget _buildEmailNotificationsSection(BuildContext context) {
    return _buildSection(
      context,
      'Email Notifications',
      'Get notifications via email',
      [
        _buildMasterToggle(
          'Email Notifications',
          'Enable all email notifications',
          _emailNotificationsEnabled,
          (value) => setState(() => _emailNotificationsEnabled = value),
        ),
        if (_emailNotificationsEnabled) ...[
          const SizedBox(height: 16),
          _buildNotificationCategory(
            'Game Invites',
            'Email invitations to join games',
            Icons.sports_esports_outlined,
            _emailGameInvites,
            (value) => setState(() => _emailGameInvites = value),
          ),
          _buildNotificationCategory(
            'Messages',
            'Email notifications for messages',
            Icons.message_outlined,
            _emailMessages,
            (value) => setState(() => _emailMessages = value),
          ),
          _buildNotificationCategory(
            'Reminders',
            'Email reminders for upcoming games',
            Icons.schedule_outlined,
            _emailReminders,
            (value) => setState(() => _emailReminders = value),
          ),
          _buildNotificationCategory(
            'Product Updates',
            'New features and announcements',
            Icons.system_update_outlined,
            _emailUpdates,
            (value) => setState(() => _emailUpdates = value),
          ),
          _buildNotificationCategory(
            'Newsletter',
            'Monthly newsletter and tips',
            Icons.newspaper_outlined,
            _emailNewsletter,
            (value) => setState(() => _emailNewsletter = value),
          ),
        ],
      ],
    );
  }

  Widget _buildSmsNotificationsSection(BuildContext context) {
    return _buildSection(
      context,
      'SMS Notifications',
      'Get notifications via text message',
      [
        _buildMasterToggle(
          'SMS Notifications',
          'Enable SMS notifications',
          _smsNotificationsEnabled,
          (value) => setState(() => _smsNotificationsEnabled = value),
        ),
        if (_smsNotificationsEnabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Standard messaging rates may apply',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationCategory(
            'Game Invites',
            'SMS invitations to join games',
            Icons.sports_esports_outlined,
            _smsGameInvites,
            (value) => setState(() => _smsGameInvites = value),
          ),
          _buildNotificationCategory(
            'Urgent Reminders',
            'Last-minute game reminders',
            Icons.schedule_outlined,
            _smsReminders,
            (value) => setState(() => _smsReminders = value),
          ),
        ],
      ],
    );
  }

  Widget _buildQuietHoursSection(BuildContext context) {
    return _buildSection(
      context,
      'Quiet Hours',
      'Pause notifications during specific times',
      [
        _buildMasterToggle(
          'Enable Quiet Hours',
          'Automatically pause notifications',
          _quietHoursEnabled,
          (value) => setState(() => _quietHoursEnabled = value),
        ),
        if (_quietHoursEnabled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector(
                  'Start Time',
                  _quietStartTime,
                  (time) => setState(() => _quietStartTime = time),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeSelector(
                  'End Time',
                  _quietEndTime,
                  (time) => setState(() => _quietEndTime = time),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bedtime_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notifications will be paused from ${_quietStartTime.format(context)} to ${_quietEndTime.format(context)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTestNotificationSection(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Notification',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send a test notification to verify your settings',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: const Icon(Icons.send),
                  label: const Text('Send Test Notification'),
                  style: ElevatedButton.styleFrom(
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

  Widget _buildMasterToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? Theme.of(context).primaryColor : null,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCategory(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
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
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (selectedTime != null) {
                onChanged(selectedTime);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    time.format(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Test notification sent!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Notification settings saved!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
