import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rewards settings data model
class RewardsSettings {
  final bool notificationsEnabled;
  final bool celebrationAnimationsEnabled;
  final bool soundEffectsEnabled;
  final double soundVolume;
  final bool autoShareAchievements;
  final bool autoShareMilestones;
  final bool profileVisibility;
  final String language;
  final bool compactDisplay;
  final bool darkMode;
  final bool hapticFeedback;
  final NotificationFrequency notificationFrequency;
  final CelebrationIntensity celebrationIntensity;

  const RewardsSettings({
    this.notificationsEnabled = true,
    this.celebrationAnimationsEnabled = true,
    this.soundEffectsEnabled = true,
    this.soundVolume = 0.7,
    this.autoShareAchievements = false,
    this.autoShareMilestones = true,
    this.profileVisibility = true,
    this.language = 'en',
    this.compactDisplay = false,
    this.darkMode = false,
    this.hapticFeedback = true,
    this.notificationFrequency = NotificationFrequency.normal,
    this.celebrationIntensity = CelebrationIntensity.medium,
  });

  RewardsSettings copyWith({
    bool? notificationsEnabled,
    bool? celebrationAnimationsEnabled,
    bool? soundEffectsEnabled,
    double? soundVolume,
    bool? autoShareAchievements,
    bool? autoShareMilestones,
    bool? profileVisibility,
    String? language,
    bool? compactDisplay,
    bool? darkMode,
    bool? hapticFeedback,
    NotificationFrequency? notificationFrequency,
    CelebrationIntensity? celebrationIntensity,
  }) {
    return RewardsSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      celebrationAnimationsEnabled: celebrationAnimationsEnabled ?? this.celebrationAnimationsEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      autoShareAchievements: autoShareAchievements ?? this.autoShareAchievements,
      autoShareMilestones: autoShareMilestones ?? this.autoShareMilestones,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      language: language ?? this.language,
      compactDisplay: compactDisplay ?? this.compactDisplay,
      darkMode: darkMode ?? this.darkMode,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      celebrationIntensity: celebrationIntensity ?? this.celebrationIntensity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'celebrationAnimationsEnabled': celebrationAnimationsEnabled,
      'soundEffectsEnabled': soundEffectsEnabled,
      'soundVolume': soundVolume,
      'autoShareAchievements': autoShareAchievements,
      'autoShareMilestones': autoShareMilestones,
      'profileVisibility': profileVisibility,
      'language': language,
      'compactDisplay': compactDisplay,
      'darkMode': darkMode,
      'hapticFeedback': hapticFeedback,
      'notificationFrequency': notificationFrequency.name,
      'celebrationIntensity': celebrationIntensity.name,
    };
  }

  factory RewardsSettings.fromMap(Map<String, dynamic> map) {
    return RewardsSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      celebrationAnimationsEnabled: map['celebrationAnimationsEnabled'] ?? true,
      soundEffectsEnabled: map['soundEffectsEnabled'] ?? true,
      soundVolume: map['soundVolume'] ?? 0.7,
      autoShareAchievements: map['autoShareAchievements'] ?? false,
      autoShareMilestones: map['autoShareMilestones'] ?? true,
      profileVisibility: map['profileVisibility'] ?? true,
      language: map['language'] ?? 'en',
      compactDisplay: map['compactDisplay'] ?? false,
      darkMode: map['darkMode'] ?? false,
      hapticFeedback: map['hapticFeedback'] ?? true,
      notificationFrequency: NotificationFrequency.values.firstWhere(
        (e) => e.name == map['notificationFrequency'],
        orElse: () => NotificationFrequency.normal,
      ),
      celebrationIntensity: CelebrationIntensity.values.firstWhere(
        (e) => e.name == map['celebrationIntensity'],
        orElse: () => CelebrationIntensity.medium,
      ),
    );
  }
}

enum NotificationFrequency {
  minimal,
  normal,
  frequent,
  all,
}

enum CelebrationIntensity {
  minimal,
  low,
  medium,
  high,
  maximum,
}

/// Settings provider
final rewardsSettingsProvider = StateNotifierProvider<RewardsSettingsNotifier, RewardsSettings>((ref) {
  return RewardsSettingsNotifier();
});

class RewardsSettingsNotifier extends StateNotifier<RewardsSettings> {
  RewardsSettingsNotifier() : super(const RewardsSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('rewards_settings');
      if (settingsJson != null) {
        final settingsMap = Map<String, dynamic>.from(
          Uri.splitQueryString(settingsJson)
        );
        state = RewardsSettings.fromMap(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading rewards settings: $e');
    }
  }

  Future<void> updateSettings(RewardsSettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = newSettings.toMap();
      final settingsJson = Uri(queryParameters: settingsMap.map(
        (key, value) => MapEntry(key, value.toString())
      )).query;
      
      await prefs.setString('rewards_settings', settingsJson);
      state = newSettings;
    } catch (e) {
      debugPrint('Error saving rewards settings: $e');
    }
  }

  void toggleNotifications(bool value) => updateSettings(state.copyWith(notificationsEnabled: value));
  void toggleCelebrationAnimations(bool value) => updateSettings(state.copyWith(celebrationAnimationsEnabled: value));
  void toggleSoundEffects(bool value) => updateSettings(state.copyWith(soundEffectsEnabled: value));
  void updateSoundVolume(double value) => updateSettings(state.copyWith(soundVolume: value));
  void toggleAutoShareAchievements(bool value) => updateSettings(state.copyWith(autoShareAchievements: value));
  void toggleAutoShareMilestones(bool value) => updateSettings(state.copyWith(autoShareMilestones: value));
  void toggleProfileVisibility(bool value) => updateSettings(state.copyWith(profileVisibility: value));
  void updateLanguage(String value) => updateSettings(state.copyWith(language: value));
  void toggleCompactDisplay(bool value) => updateSettings(state.copyWith(compactDisplay: value));
  void toggleDarkMode(bool value) => updateSettings(state.copyWith(darkMode: value));
  void toggleHapticFeedback(bool value) => updateSettings(state.copyWith(hapticFeedback: value));
  void updateNotificationFrequency(NotificationFrequency value) => updateSettings(state.copyWith(notificationFrequency: value));
  void updateCelebrationIntensity(CelebrationIntensity value) => updateSettings(state.copyWith(celebrationIntensity: value));
}

/// Rewards settings screen
class RewardsSettingsScreen extends ConsumerStatefulWidget {
  const RewardsSettingsScreen({super.key});

  @override
  ConsumerState<RewardsSettingsScreen> createState() => _RewardsSettingsScreenState();
}

class _RewardsSettingsScreenState extends ConsumerState<RewardsSettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(rewardsSettingsProvider);
    final settingsNotifier = ref.watch(rewardsSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(context, settingsNotifier),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildCelebrationSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildSoundSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildSharingSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildPrivacySection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildDisplaySection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildLanguageSection(context, settings, settingsNotifier),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Get notified about achievements and milestones'),
          value: settings.notificationsEnabled,
          onChanged: notifier.toggleNotifications,
        ),
        if (settings.notificationsEnabled) ...[
          const Divider(),
          ListTile(
            title: const Text('Notification Frequency'),
            subtitle: Text(_getFrequencyDescription(settings.notificationFrequency)),
            trailing: DropdownButton<NotificationFrequency>(
              value: settings.notificationFrequency,
              onChanged: (value) {
                if (value != null) notifier.updateNotificationFrequency(value);
              },
              items: NotificationFrequency.values.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(_getFrequencyLabel(frequency)),
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate for important achievements'),
            value: settings.hapticFeedback,
            onChanged: notifier.toggleHapticFeedback,
          ),
        ],
      ],
    );
  }

  Widget _buildCelebrationSection(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return _buildSection(
      title: 'Celebration Animations',
      icon: Icons.celebration,
      children: [
        SwitchListTile(
          title: const Text('Enable Animations'),
          subtitle: const Text('Show celebration animations for achievements'),
          value: settings.celebrationAnimationsEnabled,
          onChanged: notifier.toggleCelebrationAnimations,
        ),
        if (settings.celebrationAnimationsEnabled) ...[
          const Divider(),
          ListTile(
            title: const Text('Animation Intensity'),
            subtitle: Text(_getIntensityDescription(settings.celebrationIntensity)),
            trailing: DropdownButton<CelebrationIntensity>(
              value: settings.celebrationIntensity,
              onChanged: (value) {
                if (value != null) notifier.updateCelebrationIntensity(value);
              },
              items: CelebrationIntensity.values.map((intensity) {
                return DropdownMenuItem(
                  value: intensity,
                  child: Text(_getIntensityLabel(intensity)),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Preview Animation'),
            subtitle: const Text('Test your celebration settings'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => _showAnimationPreview(context),
          ),
        ],
      ],
    );
  }

  Widget _buildSoundSection(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return _buildSection(
      title: 'Sound Effects',
      icon: Icons.volume_up,
      children: [
        SwitchListTile(
          title: const Text('Enable Sound Effects'),
          subtitle: const Text('Play sounds for achievements and celebrations'),
          value: settings.soundEffectsEnabled,
          onChanged: notifier.toggleSoundEffects,
        ),
        if (settings.soundEffectsEnabled) ...[
          const Divider(),
          ListTile(
            title: const Text('Volume'),
            subtitle: Slider(
              value: settings.soundVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(settings.soundVolume * 100).round()}%',
              onChanged: notifier.updateSoundVolume,
            ),
          ),
          ListTile(
            title: const Text('Test Sound'),
            subtitle: const Text('Preview achievement sound'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => _testSound(context),
          ),
        ],
      ],
    );
  }

  Widget _buildSharingSection(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return _buildSection(
      title: 'Auto-Share Preferences',
      icon: Icons.share,
      children: [
        SwitchListTile(
          title: const Text('Auto-Share Achievements'),
          subtitle: const Text('Automatically share new achievements to feed'),
          value: settings.autoShareAchievements,
          onChanged: notifier.toggleAutoShareAchievements,
        ),
        SwitchListTile(
          title: const Text('Auto-Share Milestones'),
          subtitle: const Text('Share major milestones and tier promotions'),
          value: settings.autoShareMilestones,
          onChanged: notifier.toggleAutoShareMilestones,
        ),
        const Divider(),
        ListTile(
          title: const Text('Sharing Settings'),
          subtitle: const Text('Manage what gets shared automatically'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showSharingSettings(context),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return _buildSection(
      title: 'Privacy Settings',
      icon: Icons.privacy_tip,
      children: [
        SwitchListTile(
          title: const Text('Profile Visibility'),
          subtitle: const Text('Show your progress and achievements to others'),
          value: settings.profileVisibility,
          onChanged: notifier.toggleProfileVisibility,
        ),
        const Divider(),
        ListTile(
          title: const Text('Data & Privacy'),
          subtitle: const Text('Manage your rewards data and privacy'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showPrivacyDetails(context),
        ),
        ListTile(
          title: const Text('Export Data'),
          subtitle: const Text('Download your rewards and achievement data'),
          trailing: const Icon(Icons.download),
          onTap: () => _exportData(context),
        ),
      ],
    );
  }

  Widget _buildDisplaySection(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return _buildSection(
      title: 'Display Options',
      icon: Icons.display_settings,
      children: [
        SwitchListTile(
          title: const Text('Compact Display'),
          subtitle: const Text('Show more achievements in less space'),
          value: settings.compactDisplay,
          onChanged: notifier.toggleCompactDisplay,
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme for rewards screens'),
          value: settings.darkMode,
          onChanged: notifier.toggleDarkMode,
        ),
        const Divider(),
        ListTile(
          title: const Text('Theme Customization'),
          subtitle: const Text('Customize colors and appearance'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showThemeSettings(context),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return _buildSection(
      title: 'Language Preferences',
      icon: Icons.language,
      children: [
        ListTile(
          title: const Text('Language'),
          subtitle: Text(_getLanguageName(settings.language)),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showLanguageSelector(context, settings, notifier),
        ),
        ListTile(
          title: const Text('Regional Settings'),
          subtitle: const Text('Date format, number format, currency'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showRegionalSettings(context),
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
        return 'Only major achievements';
      case NotificationFrequency.normal:
        return 'Important achievements and milestones';
      case NotificationFrequency.frequent:
        return 'Most achievements and progress';
      case NotificationFrequency.all:
        return 'Every achievement and activity';
    }
  }

  String _getIntensityLabel(CelebrationIntensity intensity) {
    switch (intensity) {
      case CelebrationIntensity.minimal:
        return 'Minimal';
      case CelebrationIntensity.low:
        return 'Low';
      case CelebrationIntensity.medium:
        return 'Medium';
      case CelebrationIntensity.high:
        return 'High';
      case CelebrationIntensity.maximum:
        return 'Maximum';
    }
  }

  String _getIntensityDescription(CelebrationIntensity intensity) {
    switch (intensity) {
      case CelebrationIntensity.minimal:
        return 'Simple notifications only';
      case CelebrationIntensity.low:
        return 'Basic animations';
      case CelebrationIntensity.medium:
        return 'Moderate effects with confetti';
      case CelebrationIntensity.high:
        return 'Rich animations and effects';
      case CelebrationIntensity.maximum:
        return 'Full celebration experience';
    }
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }

  void _showResetDialog(BuildContext context, RewardsSettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all rewards settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notifier.updateSettings(const RewardsSettings());
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAnimationPreview(BuildContext context) {
    // TODO: Implement animation preview dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Animation preview coming soon!')),
    );
  }

  void _testSound(BuildContext context) {
    // TODO: Implement sound test
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔊 Testing achievement sound...')),
    );
  }

  void _showSharingSettings(BuildContext context) {
    // TODO: Navigate to detailed sharing settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing settings screen coming soon')),
    );
  }

  void _showPrivacyDetails(BuildContext context) {
    // TODO: Navigate to privacy details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy details screen coming soon')),
    );
  }

  void _exportData(BuildContext context) {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export coming soon')),
    );
  }

  void _showThemeSettings(BuildContext context) {
    // TODO: Navigate to theme customization
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme customization coming soon')),
    );
  }

  void _showLanguageSelector(BuildContext context, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, 'en', 'English', settings, notifier),
            _buildLanguageOption(context, 'ar', 'العربية', settings, notifier),
            _buildLanguageOption(context, 'es', 'Español', settings, notifier),
            _buildLanguageOption(context, 'fr', 'Français', settings, notifier),
            _buildLanguageOption(context, 'de', 'Deutsch', settings, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String code, String name, RewardsSettings settings, RewardsSettingsNotifier notifier) {
    return RadioListTile<String>(
      title: Text(name),
      value: code,
      groupValue: settings.language,
      onChanged: (value) {
        if (value != null) {
          notifier.updateLanguage(value);
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showRegionalSettings(BuildContext context) {
    // TODO: Navigate to regional settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Regional settings coming soon')),
    );
  }
}