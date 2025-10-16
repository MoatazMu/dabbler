import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/achievement.dart';

/// Achievement preferences data model
class AchievementPreferences {
  final bool showHiddenAchievements;
  final bool trackProgressNotifications;
  final bool enableProgressHints;
  final NotificationFrequency reminderFrequency;
  final Set<AchievementCategory> priorityCategories;
  final bool enableGoalSetting;
  final bool showProgressBars;
  final bool enableSmartReminders;
  final ReminderTiming reminderTiming;
  final int dailyReminderLimit;
  final bool contextualHints;
  final bool celebrateProgress;

  const AchievementPreferences({
    this.showHiddenAchievements = false,
    this.trackProgressNotifications = true,
    this.enableProgressHints = true,
    this.reminderFrequency = NotificationFrequency.normal,
    this.priorityCategories = const {},
    this.enableGoalSetting = true,
    this.showProgressBars = true,
    this.enableSmartReminders = true,
    this.reminderTiming = ReminderTiming.optimal,
    this.dailyReminderLimit = 3,
    this.contextualHints = true,
    this.celebrateProgress = true,
  });

  void _refreshData() {
    // Placeholder for refresh logic
  }

  AchievementPreferences copyWith({
    bool? showHiddenAchievements,
    bool? trackProgressNotifications,
    bool? enableProgressHints,
    NotificationFrequency? reminderFrequency,
    Set<AchievementCategory>? priorityCategories,
    bool? enableGoalSetting,
    bool? showProgressBars,
    bool? enableSmartReminders,
    ReminderTiming? reminderTiming,
    int? dailyReminderLimit,
    bool? contextualHints,
    bool? celebrateProgress,
  }) {
    return AchievementPreferences(
      showHiddenAchievements: showHiddenAchievements ?? this.showHiddenAchievements,
      trackProgressNotifications: trackProgressNotifications ?? this.trackProgressNotifications,
      enableProgressHints: enableProgressHints ?? this.enableProgressHints,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      priorityCategories: priorityCategories ?? this.priorityCategories,
      enableGoalSetting: enableGoalSetting ?? this.enableGoalSetting,
      showProgressBars: showProgressBars ?? this.showProgressBars,
      enableSmartReminders: enableSmartReminders ?? this.enableSmartReminders,
      reminderTiming: reminderTiming ?? this.reminderTiming,
      dailyReminderLimit: dailyReminderLimit ?? this.dailyReminderLimit,
      contextualHints: contextualHints ?? this.contextualHints,
      celebrateProgress: celebrateProgress ?? this.celebrateProgress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showHiddenAchievements': showHiddenAchievements,
      'trackProgressNotifications': trackProgressNotifications,
      'enableProgressHints': enableProgressHints,
      'reminderFrequency': reminderFrequency.name,
      'priorityCategories': priorityCategories.map((e) => e.name).toList(),
      'enableGoalSetting': enableGoalSetting,
      'showProgressBars': showProgressBars,
      'enableSmartReminders': enableSmartReminders,
      'reminderTiming': reminderTiming.name,
      'dailyReminderLimit': dailyReminderLimit,
      'contextualHints': contextualHints,
      'celebrateProgress': celebrateProgress,
    };
  }

  factory AchievementPreferences.fromMap(Map<String, dynamic> map) {
    return AchievementPreferences(
      showHiddenAchievements: map['showHiddenAchievements'] ?? false,
      trackProgressNotifications: map['trackProgressNotifications'] ?? true,
      enableProgressHints: map['enableProgressHints'] ?? true,
      reminderFrequency: NotificationFrequency.values.firstWhere(
        (e) => e.name == map['reminderFrequency'],
        orElse: () => NotificationFrequency.normal,
      ),
      priorityCategories: Set<AchievementCategory>.from(
        (map['priorityCategories'] as List<dynamic>?)?.map(
          (e) => AchievementCategory.values.firstWhere(
            (category) => category.name == e,
            orElse: () => AchievementCategory.gameParticipation,
          ),
        ) ?? [],
      ),
      enableGoalSetting: map['enableGoalSetting'] ?? true,
      showProgressBars: map['showProgressBars'] ?? true,
      enableSmartReminders: map['enableSmartReminders'] ?? true,
      reminderTiming: ReminderTiming.values.firstWhere(
        (e) => e.name == map['reminderTiming'],
        orElse: () => ReminderTiming.optimal,
      ),
      dailyReminderLimit: map['dailyReminderLimit'] ?? 3,
      contextualHints: map['contextualHints'] ?? true,
      celebrateProgress: map['celebrateProgress'] ?? true,
    );
  }
}

enum NotificationFrequency {
  minimal,
  normal,
  frequent,
  all,
}

enum ReminderTiming {
  morning,
  afternoon,
  evening,
  optimal,
  custom,
}

/// Goal data model
class AchievementGoal {
  final String id;
  final String achievementId;
  final String name;
  final DateTime targetDate;
  final int targetProgress;
  final int currentProgress;
  final bool isCompleted;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AchievementGoal({
    required this.id,
    required this.achievementId,
    required this.name,
    required this.targetDate,
    required this.targetProgress,
    this.currentProgress = 0,
    this.isCompleted = false,
    required this.createdAt,
    this.metadata = const {},
  });

  double get progressPercentage => targetProgress > 0 ? (currentProgress / targetProgress).clamp(0.0, 1.0) : 0.0;
  int get daysLeft => targetDate.difference(DateTime.now()).inDays;
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;
}

/// Achievement preferences provider
final achievementPreferencesProvider = StateNotifierProvider<AchievementPreferencesNotifier, AchievementPreferences>((ref) {
  return AchievementPreferencesNotifier();
});

class AchievementPreferencesNotifier extends StateNotifier<AchievementPreferences> {
  AchievementPreferencesNotifier() : super(const AchievementPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString('achievement_preferences');
      if (prefsJson != null) {
        final prefsMap = Map<String, dynamic>.from(
          Uri.splitQueryString(prefsJson)
        );
        state = AchievementPreferences.fromMap(prefsMap);
      }
    } catch (e) {
      debugPrint('Error loading achievement preferences: $e');
    }
  }

  Future<void> updatePreferences(AchievementPreferences newPreferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = newPreferences.toMap();
      final prefsJson = Uri(queryParameters: prefsMap.map(
        (key, value) => MapEntry(key, value.toString())
      )).query;
      
      await prefs.setString('achievement_preferences', prefsJson);
      state = newPreferences;
    } catch (e) {
      debugPrint('Error saving achievement preferences: $e');
    }
  }

  void toggleHiddenAchievements(bool value) => updatePreferences(state.copyWith(showHiddenAchievements: value));
  void toggleProgressNotifications(bool value) => updatePreferences(state.copyWith(trackProgressNotifications: value));
  void toggleProgressHints(bool value) => updatePreferences(state.copyWith(enableProgressHints: value));
  void updateReminderFrequency(NotificationFrequency value) => updatePreferences(state.copyWith(reminderFrequency: value));
  void updatePriorityCategories(Set<AchievementCategory> categories) => updatePreferences(state.copyWith(priorityCategories: categories));
  void toggleGoalSetting(bool value) => updatePreferences(state.copyWith(enableGoalSetting: value));
  void toggleProgressBars(bool value) => updatePreferences(state.copyWith(showProgressBars: value));
  void toggleSmartReminders(bool value) => updatePreferences(state.copyWith(enableSmartReminders: value));
  void updateReminderTiming(ReminderTiming value) => updatePreferences(state.copyWith(reminderTiming: value));
  void updateDailyReminderLimit(int value) => updatePreferences(state.copyWith(dailyReminderLimit: value));
  void toggleContextualHints(bool value) => updatePreferences(state.copyWith(contextualHints: value));
  void toggleCelebrateProgress(bool value) => updatePreferences(state.copyWith(celebrateProgress: value));
}

/// Achievement preferences screen
class AchievementPreferencesScreen extends ConsumerStatefulWidget {
  const AchievementPreferencesScreen({super.key});

  @override
  ConsumerState<AchievementPreferencesScreen> createState() => _AchievementPreferencesScreenState();
}

class _AchievementPreferencesScreenState extends ConsumerState<AchievementPreferencesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(achievementPreferencesProvider);
    final preferencesNotifier = ref.watch(achievementPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVisibilitySection(context, preferences, preferencesNotifier),
            const SizedBox(height: 24),
            _buildProgressTrackingSection(context, preferences, preferencesNotifier),
            const SizedBox(height: 24),
            _buildNotificationSection(context, preferences, preferencesNotifier),
            const SizedBox(height: 24),
            _buildCategorySection(context, preferences, preferencesNotifier),
            const SizedBox(height: 24),
            _buildGoalSection(context, preferences, preferencesNotifier),
            const SizedBox(height: 24),
            _buildReminderSection(context, preferences, preferencesNotifier),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySection(BuildContext context, AchievementPreferences preferences, AchievementPreferencesNotifier notifier) {
    return _buildSection(
      title: 'Hidden Achievement Visibility',
      icon: Icons.visibility,
      children: [
        SwitchListTile(
          title: const Text('Show Hidden Achievements'),
          subtitle: const Text('Display locked achievements with hints'),
          value: preferences.showHiddenAchievements,
          onChanged: notifier.toggleHiddenAchievements,
        ),
        if (preferences.showHiddenAchievements) ...[
          const Divider(),
          SwitchListTile(
            title: const Text('Enable Progress Hints'),
            subtitle: const Text('Show hints for unlocking hidden achievements'),
            value: preferences.enableProgressHints,
            onChanged: notifier.toggleProgressHints,
          ),
          SwitchListTile(
            title: const Text('Contextual Hints'),
            subtitle: const Text('Show relevant hints based on your activity'),
            value: preferences.contextualHints,
            onChanged: notifier.toggleContextualHints,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressTrackingSection(BuildContext context, AchievementPreferences preferences, AchievementPreferencesNotifier notifier) {
    return _buildSection(
      title: 'Progress Tracking Options',
      icon: Icons.trending_up,
      children: [
        SwitchListTile(
          title: const Text('Progress Notifications'),
          subtitle: const Text('Get notified when you make progress'),
          value: preferences.trackProgressNotifications,
          onChanged: notifier.toggleProgressNotifications,
        ),
        SwitchListTile(
          title: const Text('Show Progress Bars'),
          subtitle: const Text('Display visual progress indicators'),
          value: preferences.showProgressBars,
          onChanged: notifier.toggleProgressBars,
        ),
        SwitchListTile(
          title: const Text('Celebrate Progress'),
          subtitle: const Text('Small celebrations for milestone progress'),
          value: preferences.celebrateProgress,
          onChanged: notifier.toggleCelebrateProgress,
        ),
        const Divider(),
        ListTile(
          title: const Text('Progress Analytics'),
          subtitle: const Text('View detailed progress statistics'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showProgressAnalytics(context),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context, AchievementPreferences preferences, AchievementPreferencesNotifier notifier) {
    return _buildSection(
      title: 'Notification Frequency',
      icon: Icons.notifications,
      children: [
        ListTile(
          title: const Text('Reminder Frequency'),
          subtitle: Text(_getFrequencyDescription(preferences.reminderFrequency)),
          trailing: DropdownButton<NotificationFrequency>(
            value: preferences.reminderFrequency,
            onChanged: (value) {
              if (value != null) notifier.updateReminderFrequency(value);
            },
            items: NotificationFrequency.values.map((frequency) {
              return DropdownMenuItem(
                value: frequency,
                child: Text(_getFrequencyLabel(frequency)),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Smart Reminders'),
          subtitle: const Text('AI-powered reminder timing based on your habits'),
          value: preferences.enableSmartReminders,
          onChanged: notifier.toggleSmartReminders,
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, AchievementPreferences preferences, AchievementPreferencesNotifier notifier) {
    return _buildSection(
      title: 'Category Priorities',
      icon: Icons.category,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select categories you want to focus on:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AchievementCategory.values.map((category) {
                  final isSelected = preferences.priorityCategories.contains(category);
                  return FilterChip(
                    label: Text(_getCategoryLabel(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newCategories = Set<AchievementCategory>.from(preferences.priorityCategories);
                      if (selected) {
                        newCategories.add(category);
                      } else {
                        newCategories.remove(category);
                      }
                      notifier.updatePriorityCategories(newCategories);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Category Statistics'),
          subtitle: const Text('View progress by category'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showCategoryStats(context),
        ),
      ],
    );
  }

  Widget _buildGoalSection(BuildContext context, AchievementPreferences preferences, AchievementPreferencesNotifier notifier) {
    return _buildSection(
      title: 'Goal Setting',
      icon: Icons.flag,
      children: [
        SwitchListTile(
          title: const Text('Enable Goal Setting'),
          subtitle: const Text('Set personal targets for achievements'),
          value: preferences.enableGoalSetting,
          onChanged: notifier.toggleGoalSetting,
        ),
        if (preferences.enableGoalSetting) ...[
          const Divider(),
          ListTile(
            title: const Text('My Goals'),
            subtitle: const Text('View and manage your achievement goals'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showGoalsManager(context),
          ),
          ListTile(
            title: const Text('Create New Goal'),
            subtitle: const Text('Set a new achievement target'),
            trailing: const Icon(Icons.add),
            onTap: () => _showCreateGoal(context),
          ),
        ],
      ],
    );
  }

  Widget _buildReminderSection(BuildContext context, AchievementPreferences preferences, AchievementPreferencesNotifier notifier) {
    return _buildSection(
      title: 'Reminder Preferences',
      icon: Icons.alarm,
      children: [
        ListTile(
          title: const Text('Reminder Timing'),
          subtitle: Text(_getTimingDescription(preferences.reminderTiming)),
          trailing: DropdownButton<ReminderTiming>(
            value: preferences.reminderTiming,
            onChanged: (value) {
              if (value != null) notifier.updateReminderTiming(value);
            },
            items: ReminderTiming.values.map((timing) {
              return DropdownMenuItem(
                value: timing,
                child: Text(_getTimingLabel(timing)),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Daily Reminder Limit'),
          subtitle: Text('Maximum ${preferences.dailyReminderLimit} reminders per day'),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: preferences.dailyReminderLimit.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: preferences.dailyReminderLimit.toString(),
              onChanged: (value) => notifier.updateDailyReminderLimit(value.round()),
            ),
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Custom Reminder Schedule'),
          subtitle: const Text('Set specific times for reminders'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showReminderSchedule(context),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  String _getFrequencyLabel(NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.minimal:
        return 'Minimal';
      case NotificationFrequency.normal:
        return 'Normal';
      case NotificationFrequency.frequent:
        return 'Frequent';
      case NotificationFrequency.all:
        return 'All';
    }
  }

  String _getFrequencyDescription(NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.minimal:
        return 'Only important reminders';
      case NotificationFrequency.normal:
        return 'Balanced reminder schedule';
      case NotificationFrequency.frequent:
        return 'Regular progress reminders';
      case NotificationFrequency.all:
        return 'All available reminders';
    }
  }

  String _getTimingLabel(ReminderTiming timing) {
    switch (timing) {
      case ReminderTiming.morning:
        return 'Morning';
      case ReminderTiming.afternoon:
        return 'Afternoon';
      case ReminderTiming.evening:
        return 'Evening';
      case ReminderTiming.optimal:
        return 'Optimal';
      case ReminderTiming.custom:
        return 'Custom';
    }
  }

  String _getTimingDescription(ReminderTiming timing) {
    switch (timing) {
      case ReminderTiming.morning:
        return 'Reminders between 8-10 AM';
      case ReminderTiming.afternoon:
        return 'Reminders between 2-4 PM';
      case ReminderTiming.evening:
        return 'Reminders between 6-8 PM';
      case ReminderTiming.optimal:
        return 'AI-optimized timing based on your activity';
      case ReminderTiming.custom:
        return 'Set your own reminder times';
    }
  }

  String _getCategoryLabel(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gaming:
        return 'Gaming';
      case AchievementCategory.gameParticipation:
        return 'Games';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.profile:
        return 'Profile';
      case AchievementCategory.venue:
        return 'Venue';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.skillPerformance:
        return 'Skills';
      case AchievementCategory.milestone:
        return 'Milestones';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Achievement Preferences Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hidden Achievements:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Control whether you see locked achievements and hints.'),
              SizedBox(height: 12),
              Text('Progress Tracking:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Customize how progress is tracked and displayed.'),
              SizedBox(height: 12),
              Text('Category Priorities:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Focus on specific types of achievements.'),
              SizedBox(height: 12),
              Text('Goal Setting:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Set personal targets and deadlines.'),
              SizedBox(height: 12),
              Text('Smart Reminders:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('AI learns your patterns for optimal reminder timing.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showProgressAnalytics(BuildContext context) {
    // TODO: Navigate to progress analytics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress analytics screen coming soon')),
    );
  }

  void _showCategoryStats(BuildContext context) {
    // TODO: Navigate to category statistics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category statistics screen coming soon')),
    );
  }

  void _showGoalsManager(BuildContext context) {
    // TODO: Navigate to goals management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goals manager screen coming soon')),
    );
  }

  void _showCreateGoal(BuildContext context) {
    // TODO: Show create goal dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create goal dialog coming soon')),
    );
  }

  void _showReminderSchedule(BuildContext context) {
    // TODO: Navigate to reminder schedule screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder schedule screen coming soon')),
    );
  }
}