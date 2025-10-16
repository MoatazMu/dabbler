import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as core_error;
import '../../../providers/social_providers.dart' as social;
import '../../widgets/profile/friend_profile_header.dart';
import '../../widgets/profile/mutual_friends_section.dart';
import '../../widgets/profile/shared_activities_section.dart';
import '../../widgets/profile/common_interests_section.dart';
import '../../widgets/profile/friendship_actions_section.dart';
// friends_controller is not directly used; provider calls are via alias 'social'

class FriendProfileScreen extends ConsumerStatefulWidget {
  final String friendId;
  final bool showActions;

  const FriendProfileScreen({
    super.key,
    required this.friendId,
    this.showActions = false,
  });

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  bool _isBlocked = false;
  FriendshipStatus _friendshipStatus = FriendshipStatus.unknown;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load friend profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriendProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFriendProfile() {}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  final friendAsync = ref.watch(social.friendProfileProvider(widget.friendId));
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: friendAsync.when(
        data: (friend) => _buildProfileContent(context, theme, friend),
        loading: () => const Scaffold(
          body: Center(child: LoadingWidget()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: core_error.ErrorWidget(
              message: 'Failed to load profile: $error',
              onRetry: () => ref.refresh(social.friendProfileProvider(widget.friendId)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ThemeData theme, dynamic friend) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: theme.colorScheme.surface,
          flexibleSpace: FlexibleSpaceBar(
            background: FriendProfileHeader(
              friend: friend,
              friendshipStatus: _friendshipStatus.displayName,
              isBlocked: _isBlocked,
            ),
          ),
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => [
                if (!_isBlocked) ...[
                  PopupMenuItem(
                    value: 'message',
                    child: const ListTile(
                      leading: Icon(Icons.message),
                      title: Text('Message'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share_profile',
                    child: const ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: _isBlocked ? 'unblock' : 'block',
                  child: ListTile(
                    leading: Icon(
                      _isBlocked ? Icons.person : Icons.block,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      _isBlocked ? 'Unblock' : 'Block',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag, color: theme.colorScheme.error),
                    title: Text(
                      'Report',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(value.toString(), friend),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          // Friendship actions
          if (widget.showActions || _friendshipStatus != FriendshipStatus.friends)
            Container(
              padding: const EdgeInsets.all(16),
              child: FriendshipActionsSection(
                friendshipStatus: _friendshipStatus.displayName,
                isBlocked: _isBlocked,
                onSendRequest: () => _sendFriendRequest(friend.id),
                onAcceptRequest: () => _acceptFriendRequest(friend.id),
                onDeclineRequest: () => _declineFriendRequest(friend.id),
                onCancelRequest: () => _cancelFriendRequest(friend.id),
                onUnfriend: () => _unfriend(friend.id),
                onMessage: () => _messageUser(friend.id),
                onBlock: () => _blockUser(friend.id),
                onUnblock: () => _unblockUser(friend.id),
              ),
            ),
          
          // Tab bar
          if (!_isBlocked)
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Mutual'),
                Tab(text: 'Activities'),
                Tab(text: 'Interests'),
              ],
            ),
          
          // Tab content
          if (!_isBlocked)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMutualTab(context, theme, friend),
                  _buildActivitiesTab(context, theme, friend),
                  _buildInterestsTab(context, theme, friend),
                ],
              ),
            )
          else
            Expanded(
              child: _buildBlockedState(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildMutualTab(BuildContext context, ThemeData theme, dynamic friend) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mutual friends
          Consumer(
            builder: (context, ref, child) {
              final mutualFriendsAsync = ref.watch(social.mutualFriendsProvider(friend.id));
              
              return mutualFriendsAsync.when(
                data: (mutualFriends) => MutualFriendsSection(
                  mutualFriends: mutualFriends,
                  onViewAll: () => _viewAllMutualFriends(friend.id),
                  onFriendTap: (friendId) => _navigateToFriendProfile(friendId),
                ),
                loading: () => const LoadingWidget(),
                error: (error, stack) => core_error.ErrorWidget(
                  message: 'Failed to load mutual friends',
                  onRetry: () => ref.refresh(social.mutualFriendsProvider(friend.id)),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Connection strength
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connection Strength',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildConnectionMetric(
                    theme,
                    'Mutual Friends',
                    '12 friends in common',
                    Icons.people,
                    0.8,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildConnectionMetric(
                    theme,
                    'Common Interests',
                    '5 shared sports',
                    Icons.sports,
                    0.6,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildConnectionMetric(
                    theme,
                    'Activity Level',
                    'Both very active',
                    Icons.trending_up,
                    0.9,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(BuildContext context, ThemeData theme, dynamic friend) {
    return Consumer(
      builder: (context, ref, child) {
  final activitiesAsync = ref.watch(social.sharedActivitiesProvider(friend.id));
        
    return activitiesAsync.when(
          data: (activities) => SharedActivitiesSection(
            activities: activities,
            onActivityTap: (activity) => _viewActivity(activity.id),
            onViewAll: () => _viewAllSharedActivities(friend.id),
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: core_error.ErrorWidget(
              message: 'Failed to load shared activities',
              onRetry: () => ref.refresh(social.sharedActivitiesProvider(friend.id)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInterestsTab(BuildContext context, ThemeData theme, dynamic friend) {
    return Consumer(
      builder: (context, ref, child) {
  final interestsAsync = ref.watch(social.commonInterestsProvider(friend.id));
        
    return interestsAsync.when(
          data: (interests) => CommonInterestsSection(
            interests: interests,
            onInterestTap: (interest) => _exploreInterest(interest),
            onSuggestActivity: () => _suggestActivity(friend.id),
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: core_error.ErrorWidget(
              message: 'Failed to load common interests',
              onRetry: () => ref.refresh(social.commonInterestsProvider(friend.id)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionMetric(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    double progress,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'User Blocked',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have blocked this user. Unblock them to see their profile.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _unblockUser(widget.friendId),
              icon: const Icon(Icons.person),
              label: const Text('Unblock User'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, dynamic friend) {
    switch (action) {
      case 'message':
        _messageUser(friend.id);
        break;
      case 'share_profile':
        _shareProfile(friend);
        break;
      case 'block':
        _blockUser(friend.id);
        break;
      case 'unblock':
        _unblockUser(friend.id);
        break;
      case 'report':
        _reportUser(friend.id);
        break;
    }
  }

  void _sendFriendRequest(String userId) {
    setState(() => _friendshipStatus = FriendshipStatus.requestSent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request sent!')),
    );
  }

  void _acceptFriendRequest(String userId) {
    setState(() => _friendshipStatus = FriendshipStatus.friends);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request accepted!')),
    );
  }

  void _declineFriendRequest(String userId) {
    setState(() => _friendshipStatus = FriendshipStatus.none);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request declined')),
    );
  }

  void _cancelFriendRequest(String userId) {
    setState(() => _friendshipStatus = FriendshipStatus.none);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request cancelled')),
    );
  }

  void _unfriend(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend'),
        content: const Text('Are you sure you want to unfriend this person?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );

    if (confirm == true) {
  setState(() => _friendshipStatus = FriendshipStatus.none);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unfriended')),
      );
    }
  }

  void _messageUser(String userId) {
    Navigator.pushNamed(
      context,
      '/chat/conversation',
      arguments: {'userId': userId},
    );
  }

  void _blockUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? '
          'They won\'t be able to message you or see your posts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isBlocked = true;
        _friendshipStatus = FriendshipStatus.blocked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked')),
      );
    }
  }

  void _unblockUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: const Text('Are you sure you want to unblock this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isBlocked = false;
        _friendshipStatus = FriendshipStatus.none;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unblocked')),
      );
    }
  }

  void _reportUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => ReportUserDialog(
        userId: userId,
        onReported: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User reported successfully')),
          );
        },
      ),
    );
  }

  void _shareProfile(dynamic friend) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile link copied to clipboard')),
    );
  }

  void _viewAllMutualFriends(String friendId) {
    Navigator.pushNamed(
      context,
      '/social/mutual-friends',
      arguments: {'friendId': friendId},
    );
  }

  void _navigateToFriendProfile(String friendId) {
    Navigator.pushNamed(
      context,
      '/social/friend-profile',
      arguments: {'friendId': friendId},
    );
  }

  void _viewActivity(String activityId) {
    Navigator.pushNamed(
      context,
      '/activities/detail',
      arguments: {'activityId': activityId},
    );
  }

  void _viewAllSharedActivities(String friendId) {
    Navigator.pushNamed(
      context,
      '/social/shared-activities',
      arguments: {'friendId': friendId},
    );
  }

  void _exploreInterest(String interest) {
    Navigator.pushNamed(
      context,
      '/explore/interest',
      arguments: {'interest': interest},
    );
  }

  void _suggestActivity(String friendId) {
    Navigator.pushNamed(
      context,
      '/activities/suggest',
      arguments: {'friendId': friendId},
    );
  }
}

/// Report user dialog
class ReportUserDialog extends StatefulWidget {
  final String userId;
  final VoidCallback onReported;

  const ReportUserDialog({
    super.key,
    required this.userId,
    required this.onReported,
  });

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _reportReasons = [
    'Inappropriate behavior',
    'Harassment',
    'Fake profile',
    'Spam',
    'Hate speech',
    'Violence or threats',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this user?'),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reportReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                
                return ChoiceChip(
                  label: Text(reason),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedReason = selected ? reason : null);
                  },
                );
              }).toList(),
            ),
            
            if (_selectedReason != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedReason != null ? _submitReport : null,
          child: const Text('Report'),
        ),
      ],
    );
  }

  void _submitReport() {
    // Implement report submission
    Navigator.pop(context);
    widget.onReported();
  }
}

/// Friendship status enum
enum FriendshipStatus {
  unknown,
  none,
  requestSent,
  requestReceived,
  friends,
  blocked,
}

extension FriendshipStatusExtension on FriendshipStatus {
  String get displayName {
    switch (this) {
      case FriendshipStatus.unknown:
        return 'Unknown';
      case FriendshipStatus.none:
        return 'Not Friends';
      case FriendshipStatus.requestSent:
        return 'Request Sent';
      case FriendshipStatus.requestReceived:
        return 'Request Received';
      case FriendshipStatus.friends:
        return 'Friends';
      case FriendshipStatus.blocked:
        return 'Blocked';
    }
  }
}
