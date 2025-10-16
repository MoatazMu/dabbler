import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/badge_tier.dart';

/// Badge showcase settings data model
class BadgeShowcaseSettings {
  final ShowcaseLayout layout;
  final int displayCount;
  final BadgeSortPreference sortPreference;
  final bool showRarity;
  final bool enableAnimations;
  final bool integrateWithProfile;
  final bool showProgress;
  final bool showDescription;
  final ShowcaseTheme theme;
  final bool compactView;
  final Set<BadgeTier> visibleTiers;
  final bool showUnlockDate;
  final BadgeGrouping grouping;

  const BadgeShowcaseSettings({
    this.layout = ShowcaseLayout.grid,
    this.displayCount = 6,
    this.sortPreference = BadgeSortPreference.recent,
    this.showRarity = true,
    this.enableAnimations = true,
    this.integrateWithProfile = true,
    this.showProgress = true,
    this.showDescription = false,
    this.theme = ShowcaseTheme.auto,
    this.compactView = false,
    this.visibleTiers = const {},
    this.showUnlockDate = true,
    this.grouping = BadgeGrouping.none,
  });

  BadgeShowcaseSettings copyWith({
    ShowcaseLayout? layout,
    int? displayCount,
    BadgeSortPreference? sortPreference,
    bool? showRarity,
    bool? enableAnimations,
    bool? integrateWithProfile,
    bool? showProgress,
    bool? showDescription,
    ShowcaseTheme? theme,
    bool? compactView,
    Set<BadgeTier>? visibleTiers,
    bool? showUnlockDate,
    BadgeGrouping? grouping,
  }) {
    return BadgeShowcaseSettings(
      layout: layout ?? this.layout,
      displayCount: displayCount ?? this.displayCount,
      sortPreference: sortPreference ?? this.sortPreference,
      showRarity: showRarity ?? this.showRarity,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      integrateWithProfile: integrateWithProfile ?? this.integrateWithProfile,
      showProgress: showProgress ?? this.showProgress,
      showDescription: showDescription ?? this.showDescription,
      theme: theme ?? this.theme,
      compactView: compactView ?? this.compactView,
      visibleTiers: visibleTiers ?? this.visibleTiers,
      showUnlockDate: showUnlockDate ?? this.showUnlockDate,
      grouping: grouping ?? this.grouping,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'layout': layout.name,
      'displayCount': displayCount,
      'sortPreference': sortPreference.name,
      'showRarity': showRarity,
      'enableAnimations': enableAnimations,
      'integrateWithProfile': integrateWithProfile,
      'showProgress': showProgress,
      'showDescription': showDescription,
      'theme': theme.name,
      'compactView': compactView,
      'visibleTiers': visibleTiers.map((e) => e.name).toList(),
      'showUnlockDate': showUnlockDate,
      'grouping': grouping.name,
    };
  }

  factory BadgeShowcaseSettings.fromMap(Map<String, dynamic> map) {
    return BadgeShowcaseSettings(
      layout: ShowcaseLayout.values.firstWhere(
        (e) => e.name == map['layout'],
        orElse: () => ShowcaseLayout.grid,
      ),
      displayCount: map['displayCount'] ?? 6,
      sortPreference: BadgeSortPreference.values.firstWhere(
        (e) => e.name == map['sortPreference'],
        orElse: () => BadgeSortPreference.recent,
      ),
      showRarity: map['showRarity'] ?? true,
      enableAnimations: map['enableAnimations'] ?? true,
      integrateWithProfile: map['integrateWithProfile'] ?? true,
      showProgress: map['showProgress'] ?? true,
      showDescription: map['showDescription'] ?? false,
      theme: ShowcaseTheme.values.firstWhere(
        (e) => e.name == map['theme'],
        orElse: () => ShowcaseTheme.auto,
      ),
      compactView: map['compactView'] ?? false,
      visibleTiers: Set<BadgeTier>.from(
        (map['visibleTiers'] as List<dynamic>?)?.map(
          (e) => BadgeTier.values.firstWhere(
            (tier) => tier.name == e,
            orElse: () => BadgeTier.bronze,
          ),
        ) ?? [],
      ),
      showUnlockDate: map['showUnlockDate'] ?? true,
      grouping: BadgeGrouping.values.firstWhere(
        (e) => e.name == map['grouping'],
        orElse: () => BadgeGrouping.none,
      ),
    );
  }
}

enum ShowcaseLayout {
  grid,
  list,
  carousel,
  masonry,
  timeline,
}

enum BadgeSortPreference {
  recent,
  rarity,
  alphabetical,
  tier,
  category,
  progress,
  custom,
}

enum ShowcaseTheme {
  light,
  dark,
  auto,
  colorful,
  minimal,
}

enum BadgeGrouping {
  none,
  tier,
  category,
  date,
  rarity,
}

/// Badge showcase provider
final badgeShowcaseProvider = StateNotifierProvider<BadgeShowcaseNotifier, BadgeShowcaseSettings>((ref) {
  return BadgeShowcaseNotifier();
});

class BadgeShowcaseNotifier extends StateNotifier<BadgeShowcaseSettings> {
  BadgeShowcaseNotifier() : super(const BadgeShowcaseSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('badge_showcase_settings');
      if (settingsJson != null) {
        final settingsMap = Map<String, dynamic>.from(
          Uri.splitQueryString(settingsJson)
        );
        state = BadgeShowcaseSettings.fromMap(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading badge showcase settings: $e');
    }
  }

  Future<void> updateSettings(BadgeShowcaseSettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = newSettings.toMap();
      final settingsJson = Uri(queryParameters: settingsMap.map(
        (key, value) => MapEntry(key, value.toString())
      )).query;
      
      await prefs.setString('badge_showcase_settings', settingsJson);
      state = newSettings;
    } catch (e) {
      debugPrint('Error saving badge showcase settings: $e');
    }
  }

  void updateLayout(ShowcaseLayout layout) => updateSettings(state.copyWith(layout: layout));
  void updateDisplayCount(int count) => updateSettings(state.copyWith(displayCount: count));
  void updateSortPreference(BadgeSortPreference preference) => updateSettings(state.copyWith(sortPreference: preference));
  void toggleShowRarity(bool value) => updateSettings(state.copyWith(showRarity: value));
  void toggleEnableAnimations(bool value) => updateSettings(state.copyWith(enableAnimations: value));
  void toggleIntegrateWithProfile(bool value) => updateSettings(state.copyWith(integrateWithProfile: value));
  void toggleShowProgress(bool value) => updateSettings(state.copyWith(showProgress: value));
  void toggleShowDescription(bool value) => updateSettings(state.copyWith(showDescription: value));
  void updateTheme(ShowcaseTheme theme) => updateSettings(state.copyWith(theme: theme));
  void toggleCompactView(bool value) => updateSettings(state.copyWith(compactView: value));
  void updateVisibleTiers(Set<BadgeTier> tiers) => updateSettings(state.copyWith(visibleTiers: tiers));
  void toggleShowUnlockDate(bool value) => updateSettings(state.copyWith(showUnlockDate: value));
  void updateGrouping(BadgeGrouping grouping) => updateSettings(state.copyWith(grouping: grouping));
}

/// Badge showcase settings screen
class BadgeShowcaseSettingsScreen extends ConsumerStatefulWidget {
  const BadgeShowcaseSettingsScreen({super.key});

  @override
  ConsumerState<BadgeShowcaseSettingsScreen> createState() => _BadgeShowcaseSettingsScreenState();
}

class _BadgeShowcaseSettingsScreenState extends ConsumerState<BadgeShowcaseSettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(badgeShowcaseProvider);
    final settingsNotifier = ref.watch(badgeShowcaseProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Showcase Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () => _showPreview(context, settings),
            tooltip: 'Preview',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLayoutSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildDisplaySection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildSortingSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildVisualSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildAnimationSection(context, settings, settingsNotifier),
            const SizedBox(height: 24),
            _buildProfileIntegrationSection(context, settings, settingsNotifier),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutSection(BuildContext context, BadgeShowcaseSettings settings, BadgeShowcaseNotifier notifier) {
    return _buildSection(
      title: 'Showcase Layout',
      icon: Icons.view_comfy,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how to display your badge collection:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: ShowcaseLayout.values.map((layout) {
                  final isSelected = settings.layout == layout;
                  return GestureDetector(
                    onTap: () => notifier.updateLayout(layout),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected 
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getLayoutIcon(layout),
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLayoutLabel(layout),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected 
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplaySection(BuildContext context, BadgeShowcaseSettings settings, BadgeShowcaseNotifier notifier) {
    return _buildSection(
      title: 'Display Options',
      icon: Icons.display_settings,
      children: [
        ListTile(
          title: const Text('Display Count'),
          subtitle: Text('Show ${settings.displayCount} badges in showcase'),
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: settings.displayCount.toDouble(),
              min: 3,
              max: 12,
              divisions: 9,
              label: settings.displayCount.toString(),
              onChanged: (value) => notifier.updateDisplayCount(value.round()),
            ),
          ),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Compact View'),
          subtitle: const Text('Show more badges in less space'),
          value: settings.compactView,
          onChanged: notifier.toggleCompactView,
        ),
        SwitchListTile(
          title: const Text('Show Progress'),
          subtitle: const Text('Display progress bars for incomplete badges'),
          value: settings.showProgress,
          onChanged: notifier.toggleShowProgress,
        ),
        SwitchListTile(
          title: const Text('Show Description'),
          subtitle: const Text('Include badge descriptions'),
          value: settings.showDescription,
          onChanged: notifier.toggleShowDescription,
        ),
        SwitchListTile(
          title: const Text('Show Unlock Date'),
          subtitle: const Text('Display when badges were earned'),
          value: settings.showUnlockDate,
          onChanged: notifier.toggleShowUnlockDate,
        ),
      ],
    );
  }

  Widget _buildSortingSection(BuildContext context, BadgeShowcaseSettings settings, BadgeShowcaseNotifier notifier) {
    return _buildSection(
      title: 'Sort Preferences',
      icon: Icons.sort,
      children: [
        ListTile(
          title: const Text('Sort By'),
          subtitle: Text(_getSortDescription(settings.sortPreference)),
          trailing: DropdownButton<BadgeSortPreference>(
            value: settings.sortPreference,
            onChanged: (value) {
              if (value != null) notifier.updateSortPreference(value);
            },
            items: BadgeSortPreference.values.map((preference) {
              return DropdownMenuItem(
                value: preference,
                child: Text(_getSortLabel(preference)),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Grouping'),
          subtitle: Text(_getGroupingDescription(settings.grouping)),
          trailing: DropdownButton<BadgeGrouping>(
            value: settings.grouping,
            onChanged: (value) {
              if (value != null) notifier.updateGrouping(value);
            },
            items: BadgeGrouping.values.map((grouping) {
              return DropdownMenuItem(
                value: grouping,
                child: Text(_getGroupingLabel(grouping)),
              );
            }).toList(),
          ),
        ),
        if (settings.sortPreference == BadgeSortPreference.custom) ...[
          const Divider(),
          ListTile(
            title: const Text('Custom Sort Order'),
            subtitle: const Text('Drag to arrange your preferred order'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showCustomSortScreen(context),
          ),
        ],
      ],
    );
  }

  Widget _buildVisualSection(BuildContext context, BadgeShowcaseSettings settings, BadgeShowcaseNotifier notifier) {
    return _buildSection(
      title: 'Rarity Display',
      icon: Icons.star,
      children: [
        SwitchListTile(
          title: const Text('Show Rarity'),
          subtitle: const Text('Display rarity indicators on badges'),
          value: settings.showRarity,
          onChanged: notifier.toggleShowRarity,
        ),
        if (settings.showRarity) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visible Tiers:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BadgeTier.values.map((tier) {
                    final isSelected = settings.visibleTiers.contains(tier);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: _getTierColor(tier),
                          ),
                          const SizedBox(width: 4),
                          Text(_getTierLabel(tier)),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newTiers = Set<BadgeTier>.from(settings.visibleTiers);
                        if (selected) {
                          newTiers.add(tier);
                        } else {
                          newTiers.remove(tier);
                        }
                        notifier.updateVisibleTiers(newTiers);
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

  Widget _buildAnimationSection(BuildContext context, BadgeShowcaseSettings settings, BadgeShowcaseNotifier notifier) {
    return _buildSection(
      title: 'Animation Settings',
      icon: Icons.animation,
      children: [
        SwitchListTile(
          title: const Text('Enable Animations'),
          subtitle: const Text('Animate badge interactions and transitions'),
          value: settings.enableAnimations,
          onChanged: notifier.toggleEnableAnimations,
        ),
        if (settings.enableAnimations) ...[
          const Divider(),
          ListTile(
            title: const Text('Animation Style'),
            subtitle: const Text('Choose animation style and speed'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showAnimationSettings(context),
          ),
          ListTile(
            title: const Text('Test Animations'),
            subtitle: const Text('Preview badge animations'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => _testAnimations(context),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileIntegrationSection(BuildContext context, BadgeShowcaseSettings settings, BadgeShowcaseNotifier notifier) {
    return _buildSection(
      title: 'Profile Integration',
      icon: Icons.person,
      children: [
        SwitchListTile(
          title: const Text('Integrate with Profile'),
          subtitle: const Text('Show showcase on your profile page'),
          value: settings.integrateWithProfile,
          onChanged: notifier.toggleIntegrateWithProfile,
        ),
        if (settings.integrateWithProfile) ...[
          const Divider(),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_getThemeDescription(settings.theme)),
            trailing: DropdownButton<ShowcaseTheme>(
              value: settings.theme,
              onChanged: (value) {
                if (value != null) notifier.updateTheme(value);
              },
              items: ShowcaseTheme.values.map((theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Text(_getThemeLabel(theme)),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Profile Position'),
            subtitle: const Text('Choose where to display on profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showProfilePositionSettings(context),
          ),
        ],
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

  IconData _getLayoutIcon(ShowcaseLayout layout) {
    switch (layout) {
      case ShowcaseLayout.grid:
        return Icons.grid_view;
      case ShowcaseLayout.list:
        return Icons.view_list;
      case ShowcaseLayout.carousel:
        return Icons.view_carousel;
      case ShowcaseLayout.masonry:
        return Icons.view_quilt;
      case ShowcaseLayout.timeline:
        return Icons.timeline;
    }
  }

  String _getLayoutLabel(ShowcaseLayout layout) {
    switch (layout) {
      case ShowcaseLayout.grid:
        return 'Grid';
      case ShowcaseLayout.list:
        return 'List';
      case ShowcaseLayout.carousel:
        return 'Carousel';
      case ShowcaseLayout.masonry:
        return 'Masonry';
      case ShowcaseLayout.timeline:
        return 'Timeline';
    }
  }

  String _getSortLabel(BadgeSortPreference preference) {
    switch (preference) {
      case BadgeSortPreference.recent:
        return 'Most Recent';
      case BadgeSortPreference.rarity:
        return 'Rarity';
      case BadgeSortPreference.alphabetical:
        return 'Alphabetical';
      case BadgeSortPreference.tier:
        return 'Tier';
      case BadgeSortPreference.category:
        return 'Category';
      case BadgeSortPreference.progress:
        return 'Progress';
      case BadgeSortPreference.custom:
        return 'Custom Order';
    }
  }

  String _getSortDescription(BadgeSortPreference preference) {
    switch (preference) {
      case BadgeSortPreference.recent:
        return 'Recently earned badges first';
      case BadgeSortPreference.rarity:
        return 'Rarest badges first';
      case BadgeSortPreference.alphabetical:
        return 'Sort by badge name';
      case BadgeSortPreference.tier:
        return 'Sort by badge tier';
      case BadgeSortPreference.category:
        return 'Group by category';
      case BadgeSortPreference.progress:
        return 'Sort by completion progress';
      case BadgeSortPreference.custom:
        return 'Your custom arrangement';
    }
  }

  String _getGroupingLabel(BadgeGrouping grouping) {
    switch (grouping) {
      case BadgeGrouping.none:
        return 'No Grouping';
      case BadgeGrouping.tier:
        return 'By Tier';
      case BadgeGrouping.category:
        return 'By Category';
      case BadgeGrouping.date:
        return 'By Date';
      case BadgeGrouping.rarity:
        return 'By Rarity';
    }
  }

  String _getGroupingDescription(BadgeGrouping grouping) {
    switch (grouping) {
      case BadgeGrouping.none:
        return 'Display badges without grouping';
      case BadgeGrouping.tier:
        return 'Group badges by tier level';
      case BadgeGrouping.category:
        return 'Group badges by category';
      case BadgeGrouping.date:
        return 'Group badges by earning date';
      case BadgeGrouping.rarity:
        return 'Group badges by rarity';
    }
  }

  String _getThemeLabel(ShowcaseTheme theme) {
    switch (theme) {
      case ShowcaseTheme.light:
        return 'Light';
      case ShowcaseTheme.dark:
        return 'Dark';
      case ShowcaseTheme.auto:
        return 'Auto';
      case ShowcaseTheme.colorful:
        return 'Colorful';
      case ShowcaseTheme.minimal:
        return 'Minimal';
    }
  }

  String _getThemeDescription(ShowcaseTheme theme) {
    switch (theme) {
      case ShowcaseTheme.light:
        return 'Light theme for showcase';
      case ShowcaseTheme.dark:
        return 'Dark theme for showcase';
      case ShowcaseTheme.auto:
        return 'Match system theme';
      case ShowcaseTheme.colorful:
        return 'Vibrant colorful theme';
      case ShowcaseTheme.minimal:
        return 'Clean minimal theme';
    }
  }

  String _getTierLabel(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.platinum:
        return 'Platinum';
      case BadgeTier.diamond:
        return 'Diamond';
    }
  }

  Color _getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  void _showPreview(BuildContext context, BadgeShowcaseSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Showcase Preview'),
        content: Container(
          height: 300,
          width: double.maxFinite,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.preview, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Badge Showcase Preview'),
                Text('Coming soon...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
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

  void _showCustomSortScreen(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom sort screen coming soon')),
    );
  }

  void _showAnimationSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Animation settings coming soon')),
    );
  }

  void _testAnimations(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ Testing badge animations...')),
    );
  }

  void _showProfilePositionSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile position settings coming soon')),
    );
  }
}