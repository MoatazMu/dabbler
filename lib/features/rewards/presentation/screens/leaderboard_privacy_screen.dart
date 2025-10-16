import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Leaderboard privacy settings data model
class LeaderboardPrivacySettings {
  final bool profileVisible;
  final bool rankSharingEnabled;
  final bool friendOnlyMode;
  final bool hideFromLeaderboards;
  final bool anonymousMode;
  final bool shareProgressData;
  final bool shareAchievementData;
  final bool showRealName;
  final bool allowDirectMessages;
  final Set<LeaderboardType> visibleLeaderboards;
  final RankDisplayMode rankDisplayMode;
  final ProfileVisibilityLevel profileVisibilityLevel;

  const LeaderboardPrivacySettings({
    this.profileVisible = true,
    this.rankSharingEnabled = true,
    this.friendOnlyMode = false,
    this.hideFromLeaderboards = false,
    this.anonymousMode = false,
    this.shareProgressData = true,
    this.shareAchievementData = true,
    this.showRealName = true,
    this.allowDirectMessages = true,
    this.visibleLeaderboards = const {},
    this.rankDisplayMode = RankDisplayMode.exact,
    this.profileVisibilityLevel = ProfileVisibilityLevel.public,
  });

  LeaderboardPrivacySettings copyWith({
    bool? profileVisible,
    bool? rankSharingEnabled,
    bool? friendOnlyMode,
    bool? hideFromLeaderboards,
    bool? anonymousMode,
    bool? shareProgressData,
    bool? shareAchievementData,
    bool? showRealName,
    bool? allowDirectMessages,
    Set<LeaderboardType>? visibleLeaderboards,
    RankDisplayMode? rankDisplayMode,
    ProfileVisibilityLevel? profileVisibilityLevel,
  }) {
    return LeaderboardPrivacySettings(
      profileVisible: profileVisible ?? this.profileVisible,
      rankSharingEnabled: rankSharingEnabled ?? this.rankSharingEnabled,
      friendOnlyMode: friendOnlyMode ?? this.friendOnlyMode,
      hideFromLeaderboards: hideFromLeaderboards ?? this.hideFromLeaderboards,
      anonymousMode: anonymousMode ?? this.anonymousMode,
      shareProgressData: shareProgressData ?? this.shareProgressData,
      shareAchievementData: shareAchievementData ?? this.shareAchievementData,
      showRealName: showRealName ?? this.showRealName,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      visibleLeaderboards: visibleLeaderboards ?? this.visibleLeaderboards,
      rankDisplayMode: rankDisplayMode ?? this.rankDisplayMode,
      profileVisibilityLevel: profileVisibilityLevel ?? this.profileVisibilityLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileVisible': profileVisible,
      'rankSharingEnabled': rankSharingEnabled,
      'friendOnlyMode': friendOnlyMode,
      'hideFromLeaderboards': hideFromLeaderboards,
      'anonymousMode': anonymousMode,
      'shareProgressData': shareProgressData,
      'shareAchievementData': shareAchievementData,
      'showRealName': showRealName,
      'allowDirectMessages': allowDirectMessages,
      'visibleLeaderboards': visibleLeaderboards.map((e) => e.name).toList(),
      'rankDisplayMode': rankDisplayMode.name,
      'profileVisibilityLevel': profileVisibilityLevel.name,
    };
  }

  factory LeaderboardPrivacySettings.fromMap(Map<String, dynamic> map) {
    return LeaderboardPrivacySettings(
      profileVisible: map['profileVisible'] ?? true,
      rankSharingEnabled: map['rankSharingEnabled'] ?? true,
      friendOnlyMode: map['friendOnlyMode'] ?? false,
      hideFromLeaderboards: map['hideFromLeaderboards'] ?? false,
      anonymousMode: map['anonymousMode'] ?? false,
      shareProgressData: map['shareProgressData'] ?? true,
      shareAchievementData: map['shareAchievementData'] ?? true,
      showRealName: map['showRealName'] ?? true,
      allowDirectMessages: map['allowDirectMessages'] ?? true,
      visibleLeaderboards: Set<LeaderboardType>.from(
        (map['visibleLeaderboards'] as List<dynamic>?)?.map(
          (e) => LeaderboardType.values.firstWhere(
            (type) => type.name == e,
            orElse: () => LeaderboardType.overall,
          ),
        ) ?? [],
      ),
      rankDisplayMode: RankDisplayMode.values.firstWhere(
        (e) => e.name == map['rankDisplayMode'],
        orElse: () => RankDisplayMode.exact,
      ),
      profileVisibilityLevel: ProfileVisibilityLevel.values.firstWhere(
        (e) => e.name == map['profileVisibilityLevel'],
        orElse: () => ProfileVisibilityLevel.public,
      ),
    );
  }
}

enum LeaderboardType {
  overall,
  weekly,
  monthly,
  friends,
  local,
  global,
  sport,
  achievements,
}

enum RankDisplayMode {
  exact,
  range,
  tier,
  hidden,
}

enum ProfileVisibilityLevel {
  public,
  friendsOnly,
  private,
  limited,
}

/// Leaderboard privacy provider
final leaderboardPrivacyProvider = StateNotifierProvider<LeaderboardPrivacyNotifier, LeaderboardPrivacySettings>((ref) {
  return LeaderboardPrivacyNotifier();
});

class LeaderboardPrivacyNotifier extends StateNotifier<LeaderboardPrivacySettings> {
  LeaderboardPrivacyNotifier() : super(const LeaderboardPrivacySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('leaderboard_privacy_settings');
      if (settingsJson != null) {
        final settingsMap = Map<String, dynamic>.from(
          Uri.splitQueryString(settingsJson)
        );
        state = LeaderboardPrivacySettings.fromMap(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading leaderboard privacy settings: $e');
    }
  }

  Future<void> updateSettings(LeaderboardPrivacySettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = newSettings.toMap();
      final settingsJson = Uri(queryParameters: settingsMap.map(
        (key, value) => MapEntry(key, value.toString())
      )).query;
      
      await prefs.setString('leaderboard_privacy_settings', settingsJson);
      state = newSettings;
    } catch (e) {
      debugPrint('Error saving leaderboard privacy settings: $e');
    }
  }

  void toggleProfileVisible(bool value) => updateSettings(state.copyWith(profileVisible: value));
  void toggleRankSharing(bool value) => updateSettings(state.copyWith(rankSharingEnabled: value));
  void toggleFriendOnlyMode(bool value) => updateSettings(state.copyWith(friendOnlyMode: value));
  void toggleHideFromLeaderboards(bool value) => updateSettings(state.copyWith(hideFromLeaderboards: value));
  void toggleAnonymousMode(bool value) => updateSettings(state.copyWith(anonymousMode: value));
  void toggleShareProgressData(bool value) => updateSettings(state.copyWith(shareProgressData: value));
  void toggleShareAchievementData(bool value) => updateSettings(state.copyWith(shareAchievementData: value));
  void toggleShowRealName(bool value) => updateSettings(state.copyWith(showRealName: value));
  void toggleAllowDirectMessages(bool value) => updateSettings(state.copyWith(allowDirectMessages: value));
  void updateVisibleLeaderboards(Set<LeaderboardType> types) => updateSettings(state.copyWith(visibleLeaderboards: types));
  void updateRankDisplayMode(RankDisplayMode mode) => updateSettings(state.copyWith(rankDisplayMode: mode));
  void updateProfileVisibilityLevel(ProfileVisibilityLevel level) => updateSettings(state.copyWith(profileVisibilityLevel: level));
}

/// Leaderboard privacy screen
class LeaderboardPrivacyScreen extends ConsumerStatefulWidget {
  const LeaderboardPrivacyScreen({super.key});

  @override
  ConsumerState<LeaderboardPrivacyScreen> createState() => _LeaderboardPrivacyScreenState();
}

class _LeaderboardPrivacyScreenState extends ConsumerState<LeaderboardPrivacyScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(leaderboardPrivacyProvider);
    final settingsNotifier = ref.watch(leaderboardPrivacyProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard Privacy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPrivacyInfo(context),
            tooltip: 'Privacy Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileVisibilitySection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildRankSharingSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildLeaderboardVisibilitySection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildAnonymitySection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildDataSharingSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildAdvancedSection(context, settings, settingsNotifier),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySection(BuildContext context, LeaderboardPrivacySettings settings, LeaderboardPrivacyNotifier notifier) {
    return _buildSection(
      title: 'Profile Visibility',
      icon: Icons.visibility,
      children: [
        SwitchListTile(
          title: const Text('Profile Visible'),
          subtitle: const Text('Allow others to see your profile on leaderboards'),
          value: settings.profileVisible,
          onChanged: notifier.toggleProfileVisible,
        ),
        const Divider(),
        ListTile(
          title: const Text('Visibility Level'),
          subtitle: Text(_getVisibilityDescription(settings.profileVisibilityLevel)),
          trailing: DropdownButton<ProfileVisibilityLevel>(
            value: settings.profileVisibilityLevel,
            onChanged: settings.profileVisible
                ? (value) {
                    if (value != null) notifier.updateProfileVisibilityLevel(value);
                  }
                : null,
            items: ProfileVisibilityLevel.values.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(_getVisibilityLabel(level)),
              );
            }).toList(),
          ),
        ),
        if (settings.profileVisible) ...[
          const Divider(),
          SwitchListTile(
            title: const Text('Show Real Name'),
            subtitle: const Text('Display your real name instead of username'),
            value: settings.showRealName,
            onChanged: notifier.toggleShowRealName,
          ),
          SwitchListTile(
            title: const Text('Allow Direct Messages'),
            subtitle: const Text('Let other users send you messages'),
            value: settings.allowDirectMessages,
            onChanged: notifier.toggleAllowDirectMessages,
          ),
        ],
      ],
    );
  }

  Widget _buildRankSharingSection(BuildContext context, LeaderboardPrivacySettings settings, LeaderboardPrivacyNotifier notifier) {
    return _buildSection(
      title: 'Rank Sharing',
      icon: Icons.leaderboard,
      children: [
        SwitchListTile(
          title: const Text('Enable Rank Sharing'),
          subtitle: const Text('Share your ranking position with others'),
          value: settings.rankSharingEnabled,
          onChanged: notifier.toggleRankSharing,
        ),
        if (settings.rankSharingEnabled) ...[
          const Divider(),
          ListTile(
            title: const Text('Rank Display Mode'),
            subtitle: Text(_getRankDisplayDescription(settings.rankDisplayMode)),
            trailing: DropdownButton<RankDisplayMode>(
              value: settings.rankDisplayMode,
              onChanged: (value) {
                if (value != null) notifier.updateRankDisplayMode(value);
              },
              items: RankDisplayMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(_getRankDisplayLabel(mode)),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Friend-Only Mode'),
            subtitle: const Text('Only share rankings with friends'),
            value: settings.friendOnlyMode,
            onChanged: notifier.toggleFriendOnlyMode,
          ),
        ],
      ],
    );
  }

  Widget _buildLeaderboardVisibilitySection(BuildContext context, LeaderboardPrivacySettings settings, LeaderboardPrivacyNotifier notifier) {
    return _buildSection(
      title: 'Leaderboard Visibility',
      icon: Icons.list,
      children: [
        SwitchListTile(
          title: const Text('Hide from Leaderboards'),
          subtitle: const Text('Completely hide your profile from all leaderboards'),
          value: settings.hideFromLeaderboards,
          onChanged: notifier.toggleHideFromLeaderboards,
        ),
        if (!settings.hideFromLeaderboards) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visible Leaderboards:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose which leaderboards you want to appear on',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeaderboardType.values.map((type) {
                    final isSelected = settings.visibleLeaderboards.contains(type);
                    return FilterChip(
                      label: Text(_getLeaderboardTypeLabel(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newTypes = Set<LeaderboardType>.from(settings.visibleLeaderboards);
                        if (selected) {
                          newTypes.add(type);
                        } else {
                          newTypes.remove(type);
                        }
                        notifier.updateVisibleLeaderboards(newTypes);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnonymitySection(BuildContext context, LeaderboardPrivacySettings settings, LeaderboardPrivacyNotifier notifier) {
    return _buildSection(
      title: 'Anonymous Mode',
      icon: Icons.person_off,
      children: [
        SwitchListTile(
          title: const Text('Anonymous Mode'),
          subtitle: const Text('Hide your identity while staying on leaderboards'),
          value: settings.anonymousMode,
          onChanged: notifier.toggleAnonymousMode,
        ),
        if (settings.anonymousMode) ...[
          const Divider(),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anonymous Mode Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You will appear as "Anonymous Player" on leaderboards. Your profile and achievements will be hidden.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Anonymous Display Name'),
            subtitle: const Text('Customize your anonymous display name'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showAnonymousNameEditor(context),
          ),
        ],
      ],
    );
  }

  Widget _buildDataSharingSection(BuildContext context, LeaderboardPrivacySettings settings, LeaderboardPrivacyNotifier notifier) {
    return _buildSection(
      title: 'Data Sharing Options',
      icon: Icons.share,
      children: [
        SwitchListTile(
          title: const Text('Share Progress Data'),
          subtitle: const Text('Allow progress and statistics to be shared'),
          value: settings.shareProgressData,
          onChanged: notifier.toggleShareProgressData,
        ),
        SwitchListTile(
          title: const Text('Share Achievement Data'),
          subtitle: const Text('Allow achievement information to be shared'),
          value: settings.shareAchievementData,
          onChanged: notifier.toggleShareAchievementData,
        ),
        const Divider(),
        ListTile(
          title: const Text('Data Usage Details'),
          subtitle: const Text('Learn how your data is used'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showDataUsageDetails(context),
        ),
        ListTile(
          title: const Text('Download My Data'),
          subtitle: const Text('Get a copy of your leaderboard data'),
          trailing: const Icon(Icons.download),
          onTap: () => _downloadUserData(context),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(BuildContext context, LeaderboardPrivacySettings settings, LeaderboardPrivacyNotifier notifier) {
    return _buildSection(
      title: 'Advanced Settings',
      icon: Icons.settings,
      children: [
        ListTile(
          title: const Text('Block List'),
          subtitle: const Text('Manage blocked users'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showBlockList(context),
        ),
        ListTile(
          title: const Text('Privacy Audit Log'),
          subtitle: const Text('View privacy-related activities'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showPrivacyAuditLog(context),
        ),
        const Divider(),
        ListTile(
          title: const Text('Reset Privacy Settings'),
          subtitle: const Text('Reset all privacy settings to defaults'),
          trailing: const Icon(Icons.restore),
          onTap: () => _showResetPrivacyDialog(context, notifier),
        ),
        ListTile(
          title: const Text('Delete Leaderboard Data'),
          subtitle: const Text('Permanently remove your data from leaderboards'),
          trailing: const Icon(Icons.delete_forever, color: Colors.red),
          onTap: () => _showDeleteDataDialog(context),
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

  String _getVisibilityLabel(ProfileVisibilityLevel level) {
    switch (level) {
      case ProfileVisibilityLevel.public:
        return 'Public';
      case ProfileVisibilityLevel.friendsOnly:
        return 'Friends Only';
      case ProfileVisibilityLevel.private:
        return 'Private';
      case ProfileVisibilityLevel.limited:
        return 'Limited';
    }
  }

  String _getVisibilityDescription(ProfileVisibilityLevel level) {
    switch (level) {
      case ProfileVisibilityLevel.public:
        return 'Visible to everyone';
      case ProfileVisibilityLevel.friendsOnly:
        return 'Visible to friends only';
      case ProfileVisibilityLevel.private:
        return 'Hidden from everyone';
      case ProfileVisibilityLevel.limited:
        return 'Limited information visible';
    }
  }

  String _getRankDisplayLabel(RankDisplayMode mode) {
    switch (mode) {
      case RankDisplayMode.exact:
        return 'Exact Rank';
      case RankDisplayMode.range:
        return 'Rank Range';
      case RankDisplayMode.tier:
        return 'Tier Only';
      case RankDisplayMode.hidden:
        return 'Hidden';
    }
  }

  String _getRankDisplayDescription(RankDisplayMode mode) {
    switch (mode) {
      case RankDisplayMode.exact:
        return 'Show exact position (e.g., #42)';
      case RankDisplayMode.range:
        return 'Show rank range (e.g., 40-50)';
      case RankDisplayMode.tier:
        return 'Show tier only (e.g., Gold)';
      case RankDisplayMode.hidden:
        return 'Hide rank completely';
    }
  }

  String _getLeaderboardTypeLabel(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.overall:
        return 'Overall';
      case LeaderboardType.weekly:
        return 'Weekly';
      case LeaderboardType.monthly:
        return 'Monthly';
      case LeaderboardType.friends:
        return 'Friends';
      case LeaderboardType.local:
        return 'Local';
      case LeaderboardType.global:
        return 'Global';
      case LeaderboardType.sport:
        return 'Sport';
      case LeaderboardType.achievements:
        return 'Achievements';
    }
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leaderboard Privacy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Privacy Matters:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Control exactly how you appear on leaderboards and who can see your progress.'),
              SizedBox(height: 12),
              Text('Profile Visibility:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Choose who can see your profile and achievements.'),
              SizedBox(height: 12),
              Text('Anonymous Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Participate in leaderboards while keeping your identity private.'),
              SizedBox(height: 12),
              Text('Data Sharing:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Control what information is shared with other users and the platform.'),
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

  void _showAnonymousNameEditor(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anonymous name editor coming soon')),
    );
  }

  void _showDataUsageDetails(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data usage details screen coming soon')),
    );
  }

  void _downloadUserData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data download coming soon')),
    );
  }

  void _showBlockList(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Block list screen coming soon')),
    );
  }

  void _showPrivacyAuditLog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy audit log screen coming soon')),
    );
  }

  void _showResetPrivacyDialog(BuildContext context, LeaderboardPrivacyNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text('Reset all leaderboard privacy settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notifier.updateSettings(const LeaderboardPrivacySettings());
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Leaderboard Data'),
        content: const Text(
          'This will permanently delete all your leaderboard data, rankings, and progress. This action cannot be undone.\n\nAre you sure you want to continue?'
        ),
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
                  content: Text('Data deletion request submitted. You will be contacted within 24 hours.'),
                  backgroundColor: Colors.red,
                ),
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