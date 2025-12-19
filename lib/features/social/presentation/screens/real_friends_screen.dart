import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/social_providers.dart';

/// Friends screen showing friend lists and management with real data
class RealFriendsScreen extends ConsumerStatefulWidget {
  const RealFriendsScreen({super.key});

  @override
  ConsumerState<RealFriendsScreen> createState() => _RealFriendsScreenState();
}

class _RealFriendsScreenState extends ConsumerState<RealFriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load friends data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
      ref.read(simpleFriendsControllerProvider.notifier).loadSuggestions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simpleFriendsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // TODO: Implement add friend flow
            },
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Friends (${state.friends.length})'),
            Tab(text: 'Requests (${state.incomingRequests.length})'),
            const Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: state.error != null
          ? _buildError(state.error!)
          : TabBarView(
              controller: _tabController,
              children: [
                // All Friends Tab
                _buildFriendsList(state.friends),

                // Friend Requests Tab
                _buildFriendRequests(state.incomingRequests),

                // Friend Suggestions Tab (placeholder)
                _buildFriendSuggestions(),
              ],
            ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(List<Map<String, dynamic>> friends) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start connecting with other players!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          final profile = friend['profile'] as Map<String, dynamic>?;
          final friendId =
              friend['peer_user_id'] as String? ??
              friend['user_id'] as String? ??
              '';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage: profile?['avatar_url'] != null
                    ? NetworkImage(profile!['avatar_url'] as String)
                    : null,
                child: profile?['avatar_url'] == null
                    ? Icon(Icons.person, color: Colors.grey[600])
                    : null,
              ),
              title: Text(
                profile?['full_name'] as String? ??
                    profile?['display_name'] as String? ??
                    'Unknown User',
              ),
              subtitle: Text('@${profile?['username'] as String? ?? 'user'}'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('View Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'unfriend',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Unfriend', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Block', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'unfriend':
                      _showUnfriendDialog(friendId);
                      break;
                    case 'block':
                      _showBlockDialog(friendId);
                      break;
                    case 'profile':
                      // TODO: Navigate to profile
                      break;
                  }
                },
              ),
              onTap: () {
                // TODO: Navigate to friend profile
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendRequests(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final profile = request['profile'] as Map<String, dynamic>?;
          final fromUserId = request['user_id'] as String? ?? '';
          final state = ref.watch(simpleFriendsControllerProvider);
          final isProcessing = state.processingIds[fromUserId] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: profile?['avatar_url'] != null
                        ? NetworkImage(profile!['avatar_url'] as String)
                        : null,
                    child: profile?['avatar_url'] == null
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?['full_name'] as String? ??
                              profile?['display_name'] as String? ??
                              'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '@${profile?['username'] as String? ?? 'user'}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isProcessing
                                    ? null
                                    : () {
                                        ref
                                            .read(
                                              simpleFriendsControllerProvider
                                                  .notifier,
                                            )
                                            .acceptRequest(fromUserId);
                                      },
                                child: isProcessing
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Accept'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isProcessing
                                    ? null
                                    : () {
                                        ref
                                            .read(
                                              simpleFriendsControllerProvider
                                                  .notifier,
                                            )
                                            .rejectRequest(fromUserId);
                                      },
                                child: const Text('Decline'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendSuggestions() {
    final state = ref.watch(simpleFriendsControllerProvider);

    if (state.isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add more friends to get suggestions',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(simpleFriendsControllerProvider.notifier)
                    .loadSuggestions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(simpleFriendsControllerProvider.notifier)
            .loadSuggestions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = state.suggestions[index];
          final userId = suggestion['user_id'] as String;
          final mutualCount = suggestion['mutual_friends_count'] as int? ?? 0;
          final isProcessing = state.processingIds[userId] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: suggestion['avatar_url'] != null
                        ? NetworkImage(suggestion['avatar_url'] as String)
                        : null,
                    child: suggestion['avatar_url'] == null
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion['full_name'] as String? ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '@${suggestion['username'] as String? ?? 'user'}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        if (mutualCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$mutualCount mutual friend${mutualCount > 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () {
                            ref
                                .read(simpleFriendsControllerProvider.notifier)
                                .sendRequest(userId);
                          },
                    icon: isProcessing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUnfriendDialog(String friendId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend User?'),
        content: const Text(
          'Are you sure you want to remove this person from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(simpleFriendsControllerProvider.notifier)
                  .removeFriend(friendId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: const Text(
          'This user will no longer be able to see your profile or send you messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(simpleFriendsControllerProvider.notifier)
                  .blockUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search Users'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Enter name or username',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      ref
                          .read(simpleFriendsControllerProvider.notifier)
                          .searchUsers('');
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (query) {
                  if (query.length >= 2) {
                    ref
                        .read(simpleFriendsControllerProvider.notifier)
                        .searchUsers(query);
                  } else if (query.isEmpty) {
                    ref
                        .read(simpleFriendsControllerProvider.notifier)
                        .searchUsers('');
                  }
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(simpleFriendsControllerProvider);

                  if (state.isSearching) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state.searchResults.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        searchController.text.isEmpty
                            ? 'Start typing to search'
                            : 'No users found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = state.searchResults[index];
                        final userId = user['user_id'] as String;
                        final isFriend = user['is_friend'] as bool? ?? false;
                        final hasPendingRequest =
                            user['has_pending_request'] as bool? ?? false;
                        final isProcessing =
                            state.processingIds[userId] == true;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: user['avatar_url'] != null
                                ? NetworkImage(user['avatar_url'] as String)
                                : null,
                            child: user['avatar_url'] == null
                                ? Icon(Icons.person, color: Colors.grey[600])
                                : null,
                          ),
                          title: Text(
                            user['full_name'] as String? ?? 'Unknown User',
                          ),
                          subtitle: Text(
                            '@${user['username'] as String? ?? 'user'}',
                          ),
                          trailing: isFriend
                              ? const Chip(
                                  label: Text('Friends'),
                                  backgroundColor: Colors.green,
                                )
                              : hasPendingRequest
                              ? const Chip(
                                  label: Text('Pending'),
                                  backgroundColor: Colors.orange,
                                )
                              : ElevatedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () {
                                          ref
                                              .read(
                                                simpleFriendsControllerProvider
                                                    .notifier,
                                              )
                                              .sendRequest(userId);
                                        },
                                  icon: isProcessing
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.person_add, size: 18),
                                  label: const Text('Add'),
                                ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      searchController.dispose();
    });
  }
}
