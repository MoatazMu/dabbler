import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum PrivacyPreset { public, friendsOnly, private }

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Privacy preset
  PrivacyPreset _selectedPreset = PrivacyPreset.public;

  // Individual data toggles
  bool _showProfilePhoto = true;
  bool _showRealName = true;
  bool _showEmail = false;
  bool _showPhoneNumber = false;
  bool _showLocation = true;
  bool _showSportsProfiles = true;
  bool _showActivityStatus = true;
  bool _showGameHistory = true;
  bool _showFriendsList = false;
  bool _showStatistics = true;

  // Data sharing preferences
  bool _shareWithFriends = true;
  bool _shareWithTeammates = true;
  bool _shareForMatching = true;
  bool _shareForRecommendations = false;
  bool _shareAnalytics = false;

  // Blocked users list (mock data)
  final List<String> _blockedUsers = ['user123', 'player456'];

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

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
              SliverToBoxAdapter(child: _buildPrivacyPresetsSection(context)),
              SliverToBoxAdapter(
                child: _buildProfileVisibilitySection(context),
              ),
              SliverToBoxAdapter(child: _buildDataSharingSection(context)),
              SliverToBoxAdapter(child: _buildBlockedUsersSection(context)),
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
          'Privacy Settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
      actions: [
        TextButton(onPressed: _saveSettings, child: const Text('Save')),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPrivacyPresetsSection(BuildContext context) {
    return _buildSection(
      context,
      'Privacy Presets',
      'Choose a preset to quickly configure your privacy settings',
      [
        ...PrivacyPreset.values.map((preset) {
          return _buildPrivacyPresetCard(context, preset);
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can always customize individual settings below',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPresetCard(BuildContext context, PrivacyPreset preset) {
    final isSelected = _selectedPreset == preset;
    final presetData = _getPresetData(preset);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPreset = preset;
              _applyPreset(preset);
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.05)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: presetData['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    presetData['icon'],
                    color: presetData['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presetData['title'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presetData['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySection(BuildContext context) {
    return _buildSection(
      context,
      'Profile Visibility',
      'Control what information others can see about you',
      [
        _buildPrivacyToggle(
          'Profile Photo',
          'Show your profile picture',
          Icons.account_circle_outlined,
          _showProfilePhoto,
          (value) => setState(() => _showProfilePhoto = value),
          'Your profile photo helps others recognize you',
        ),
        _buildPrivacyToggle(
          'Real Name',
          'Show your full name',
          Icons.person_outline,
          _showRealName,
          (value) => setState(() => _showRealName = value),
          'Others will see your real name instead of username',
        ),
        _buildPrivacyToggle(
          'Email Address',
          'Show your email to others',
          Icons.email_outlined,
          _showEmail,
          (value) => setState(() => _showEmail = value),
          'Not recommended for privacy reasons',
        ),
        _buildPrivacyToggle(
          'Phone Number',
          'Show your phone number',
          Icons.phone_outlined,
          _showPhoneNumber,
          (value) => setState(() => _showPhoneNumber = value),
          'Only visible to teammates for coordination',
        ),
        _buildPrivacyToggle(
          'Location',
          'Show your general location',
          Icons.location_on_outlined,
          _showLocation,
          (value) => setState(() => _showLocation = value),
          'Helps with local game matching',
        ),
        _buildPrivacyToggle(
          'Sports Profiles',
          'Show your sports and skill levels',
          Icons.sports_outlined,
          _showSportsProfiles,
          (value) => setState(() => _showSportsProfiles = value),
          'Essential for finding suitable games',
        ),
        _buildPrivacyToggle(
          'Activity Status',
          'Show when you\'re online',
          Icons.circle,
          _showActivityStatus,
          (value) => setState(() => _showActivityStatus = value),
          'Let others know when you\'re available',
        ),
        _buildPrivacyToggle(
          'Game History',
          'Show your past games',
          Icons.history_outlined,
          _showGameHistory,
          (value) => setState(() => _showGameHistory = value),
          'Demonstrates your experience level',
        ),
        _buildPrivacyToggle(
          'Friends List',
          'Show your friends publicly',
          Icons.people_outline,
          _showFriendsList,
          (value) => setState(() => _showFriendsList = value),
          'Others can see who you\'re connected with',
        ),
        _buildPrivacyToggle(
          'Statistics',
          'Show your performance stats',
          Icons.bar_chart_outlined,
          _showStatistics,
          (value) => setState(() => _showStatistics = value),
          'Your game statistics and achievements',
        ),
      ],
    );
  }

  Widget _buildDataSharingSection(BuildContext context) {
    return _buildSection(
      context,
      'Data Sharing',
      'Control how your data is used to improve your experience',
      [
        _buildPrivacyToggle(
          'Share with Friends',
          'Friends can see your activity',
          Icons.group_outlined,
          _shareWithFriends,
          (value) => setState(() => _shareWithFriends = value),
          'Share game invites and activity updates',
        ),
        _buildPrivacyToggle(
          'Share with Teammates',
          'Teammates can coordinate with you',
          Icons.sports_outlined,
          _shareWithTeammates,
          (value) => setState(() => _shareWithTeammates = value),
          'Share availability and contact info',
        ),
        _buildPrivacyToggle(
          'Use for Game Matching',
          'Help us find suitable games for you',
          Icons.auto_awesome_outlined,
          _shareForMatching,
          (value) => setState(() => _shareForMatching = value),
          'Uses your preferences and skill level',
        ),
        _buildPrivacyToggle(
          'Personalized Recommendations',
          'Get recommendations based on your activity',
          Icons.recommend_outlined,
          _shareForRecommendations,
          (value) => setState(() => _shareForRecommendations = value),
          'Suggests games, players, and events',
        ),
        _buildPrivacyToggle(
          'Anonymous Analytics',
          'Help improve the app',
          Icons.analytics_outlined,
          _shareAnalytics,
          (value) => setState(() => _shareAnalytics = value),
          'Anonymous usage data for app improvements',
        ),
      ],
    );
  }

  Widget _buildBlockedUsersSection(BuildContext context) {
    return _buildSection(
      context,
      'Blocked Users',
      'Manage users you\'ve blocked from contacting you',
      [
        if (_blockedUsers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You haven\'t blocked any users',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          )
        else
          ..._blockedUsers.map((username) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.block, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Blocked user',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _unblockUser(username),
                    child: const Text('Unblock'),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showBlockUserDialog,
            icon: const Icon(Icons.block),
            label: const Text('Block a User'),
            style: OutlinedButton.styleFrom(
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

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    String tooltip,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: value
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: value
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showTooltip(context, title, tooltip),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
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
                const SizedBox(width: 8),
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

  Map<String, dynamic> _getPresetData(PrivacyPreset preset) {
    switch (preset) {
      case PrivacyPreset.public:
        return {
          'title': 'Public',
          'description':
              'Your profile is visible to everyone for easy discovery',
          'icon': Icons.public,
          'color': Colors.green,
        };
      case PrivacyPreset.friendsOnly:
        return {
          'title': 'Friends Only',
          'description': 'Only your friends can see your full profile',
          'icon': Icons.group,
          'color': Colors.blue,
        };
      case PrivacyPreset.private:
        return {
          'title': 'Private',
          'description': 'Minimal information is shared publicly',
          'icon': Icons.lock,
          'color': Colors.orange,
        };
    }
  }

  void _applyPreset(PrivacyPreset preset) {
    switch (preset) {
      case PrivacyPreset.public:
        _showProfilePhoto = true;
        _showRealName = true;
        _showEmail = false;
        _showPhoneNumber = false;
        _showLocation = true;
        _showSportsProfiles = true;
        _showActivityStatus = true;
        _showGameHistory = true;
        _showFriendsList = true;
        _showStatistics = true;
        _shareWithFriends = true;
        _shareWithTeammates = true;
        _shareForMatching = true;
        _shareForRecommendations = true;
        break;
      case PrivacyPreset.friendsOnly:
        _showProfilePhoto = true;
        _showRealName = true;
        _showEmail = false;
        _showPhoneNumber = false;
        _showLocation = true;
        _showSportsProfiles = true;
        _showActivityStatus = true;
        _showGameHistory = false;
        _showFriendsList = false;
        _showStatistics = false;
        _shareWithFriends = true;
        _shareWithTeammates = true;
        _shareForMatching = true;
        _shareForRecommendations = false;
        break;
      case PrivacyPreset.private:
        _showProfilePhoto = false;
        _showRealName = false;
        _showEmail = false;
        _showPhoneNumber = false;
        _showLocation = false;
        _showSportsProfiles = true;
        _showActivityStatus = false;
        _showGameHistory = false;
        _showFriendsList = false;
        _showStatistics = false;
        _shareWithFriends = false;
        _shareWithTeammates = true;
        _shareForMatching = true;
        _shareForRecommendations = false;
        break;
    }
  }

  void _showTooltip(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the username of the user you want to block:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _blockUser(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _blockUser(String username) {
    setState(() {
      if (!_blockedUsers.contains(username)) {
        _blockedUsers.add(username);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User $username has been blocked'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _unblockUser(String username) {
    setState(() {
      _blockedUsers.remove(username);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User $username has been unblocked'),
        backgroundColor: Colors.green,
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
            Text('Privacy settings saved!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
