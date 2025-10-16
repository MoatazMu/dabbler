import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as core_error;
import '../../widgets/friends/friend_tile.dart';
import '../../controllers/friends_controller.dart';
import '../../../providers/social_providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  FriendSortOption _sortOption = FriendSortOption.name;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    
    // Load friends data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsControllerProvider.notifier).loadFriends();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friendsState = ref.watch(friendsControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme, friendsState),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search friends...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<FriendSortOption>(
                  icon: Icon(_sortOption.icon),
                  onSelected: (sortOption) {
                    setState(() => _sortOption = sortOption);
                    // Note: setSortOption method needs to be implemented
                  },
                  itemBuilder: (context) => FriendSortOption.values
                      .map((option) => PopupMenuItem(
                            value: option,
                            child: Row(
                              children: [
                                Icon(option.icon),
                                const SizedBox(width: 8),
                                Text(option.displayName),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('All Friends'),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(totalFriendsCountProvider);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 8,
                    ),
                    const SizedBox(width: 4),
                    const Text('Online'),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(onlineFriendsCountProvider);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, size: 16),
                    const SizedBox(width: 4),
                    const Text('Blocked'),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(blockedUsersCountProvider);
                        if (count > 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: theme.colorScheme.onError,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllFriendsTab(context, theme, friendsState),
                _buildOnlineFriendsTab(context, theme, friendsState),
                _buildBlockedUsersTab(context, theme, friendsState),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/social/find-friends'),
        tooltip: 'Find Friends',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    FriendsState friendsState,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: const Text('Friends'),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/social/friend-requests'),
          icon: Stack(
            children: [
              const Icon(Icons.person_add),
              Consumer(
                builder: (context, ref, child) {
                  final hasRequests = ref.watch(hasPendingFriendRequestsProvider);
                  if (!hasRequests) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sync_contacts',
              child: ListTile(
                leading: Icon(Icons.sync),
                title: Text('Sync Contacts'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Friend Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildAllFriendsTab(
    BuildContext context,
    ThemeData theme,
    FriendsState friendsState,
  ) {
    if (friendsState.isLoading && friendsState.allFriends.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (friendsState.error != null && friendsState.allFriends.isEmpty) {
      return Center(
        child: core_error.ErrorWidget(
          message: friendsState.error!,
          onRetry: () => ref.read(friendsControllerProvider.notifier).loadFriends(),
        ),
      );
    }

    final filteredFriends = _getFilteredFriends(friendsState.allFriends);
    
    if (filteredFriends.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
        title: _searchQuery.isNotEmpty ? 'No friends found' : 'No friends yet',
        subtitle: _searchQuery.isNotEmpty 
          ? 'Try a different search term'
          : 'Start connecting with other players',
        action: _searchQuery.isEmpty 
          ? TextButton(
              onPressed: () => Navigator.pushNamed(context, '/social/find-friends'),
              child: const Text('Find Friends'),
            )
          : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(friendsControllerProvider.notifier).loadFriends(),
      child: Row(
        children: [
          // Friends list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                
                return FriendTile(
                  friend: friend,
                  onTap: () => _navigateToFriendProfile(friend.id),
                  onMessage: () => _startConversation(friend.id),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'message',
                        child: const ListTile(
                          leading: Icon(Icons.message),
                          title: Text('Message'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'view_profile',
                        child: const ListTile(
                          leading: Icon(Icons.person),
                          title: Text('View Profile'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'unfriend',
                        child: ListTile(
                          leading: Icon(Icons.person_remove, color: theme.colorScheme.error),
                          title: Text('Unfriend', style: TextStyle(color: theme.colorScheme.error)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleFriendAction(value.toString(), friend),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineFriendsTab(
    BuildContext context,
    ThemeData theme,
    FriendsState friendsState,
  ) {
    final onlineFriends = friendsState.allFriends
        .where((friend) => friendsState.onlineUsers.contains(friend.id))
        .toList();
    
    if (onlineFriends.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.wifi_off,
        title: 'No friends online',
        subtitle: 'Your friends will appear here when they\'re active',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: onlineFriends.length,
      itemBuilder: (context, index) {
        final friend = onlineFriends[index];
        
        return FriendTile(
          friend: friend,
          onTap: () => _navigateToFriendProfile(friend.id),
          onMessage: () => _startConversation(friend.id),
        );
      },
    );
  }

  Widget _buildBlockedUsersTab(
    BuildContext context,
    ThemeData theme,
    FriendsState friendsState,
  ) {
    final blockedUsers = friendsState.blockedUsers;
    
    if (blockedUsers.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.block,
        title: 'No blocked users',
        subtitle: 'Users you block will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: blockedUsers.length,
      itemBuilder: (context, index) {
        final user = blockedUsers[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
              child: user.profileImageUrl == null ? Text(user.displayName[0].toUpperCase()) : null,
            ),
            title: Text(user.displayName),
            subtitle: Text(user.email ?? 'No email'),
            trailing: TextButton(
              onPressed: () => _unblockUser(user.id),
              child: const Text('Unblock'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  List<dynamic> _getFilteredFriends(List<dynamic> friends) {
    if (_searchQuery.isEmpty) return friends;
    
    return friends.where((friend) {
      final name = friend.displayName.toLowerCase();
      final email = friend.email?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sync_contacts':
        _syncContacts();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings/friends');
        break;
    }
  }

  void _handleFriendAction(String action, dynamic friend) {
    switch (action) {
      case 'message':
        _startConversation(friend.id);
        break;
      case 'view_profile':
        _navigateToFriendProfile(friend.id);
        break;
      case 'unfriend':
        _showUnfriendDialog(friend);
        break;
    }
  }

  void _startConversation(String friendId) {
    Navigator.pushNamed(
      context,
      '/chat/conversation',
      arguments: {'userId': friendId},
    );
  }

  void _navigateToFriendProfile(String friendId) {
    Navigator.pushNamed(
      context,
      '/social/friend-profile',
      arguments: {'friendId': friendId},
    );
  }

  void _unblockUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: const Text('Are you sure you want to unblock this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unblock functionality coming soon')),
              );
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showUnfriendDialog(dynamic friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend'),
        content: Text('Are you sure you want to unfriend ${friend.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unfriend functionality coming soon')),
              );
            },
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  void _syncContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync contacts functionality coming soon')),
    );
  }
}

/// Friend sort options
enum FriendSortOption {
  name,
  recent,
  location,
  status,
}

extension FriendSortOptionExtension on FriendSortOption {
  String get displayName {
    switch (this) {
      case FriendSortOption.name:
        return 'Name';
      case FriendSortOption.recent:
        return 'Recent';
      case FriendSortOption.location:
        return 'Location';
      case FriendSortOption.status:
        return 'Status';
    }
  }

  IconData get icon {
    switch (this) {
      case FriendSortOption.name:
        return Icons.sort_by_alpha;
      case FriendSortOption.recent:
        return Icons.schedule;
      case FriendSortOption.location:
        return Icons.location_on;
      case FriendSortOption.status:
        return Icons.circle;
    }
  }
}

/// Friend status enum
enum FriendStatus {
  online,
  offline,
  away,
  busy,
}

extension FriendStatusExtension on FriendStatus {
  Color get color {
    switch (this) {
      case FriendStatus.online:
        return Colors.green;
      case FriendStatus.offline:
        return Colors.grey;
      case FriendStatus.away:
        return Colors.orange;
      case FriendStatus.busy:
        return Colors.red;
    }
  }

  String get displayName {
    switch (this) {
      case FriendStatus.online:
        return 'Online';
      case FriendStatus.offline:
        return 'Offline';
      case FriendStatus.away:
        return 'Away';
      case FriendStatus.busy:
        return 'Busy';
    }
  }
}
