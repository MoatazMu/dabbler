import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../providers/social_providers.dart';
import '../../widgets/friend_requests/sent_request_card.dart';
import '../../widgets/friend_requests/bulk_actions_bar.dart';
import '../../controllers/friend_requests_controller.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedRequests = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load friend requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendRequestsControllerProvider.notifier).loadFriendRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestsState = ref.watch(friendRequestsControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme, requestsState),
      body: Column(
        children: [
          // Selection mode bar
          if (_isSelectionMode)
            BulkActionsBar(
              selectedCount: _selectedRequests.length,
              onAcceptAll: () => _handleBulkAction('accept'),
              onDeclineAll: () => _handleBulkAction('decline'),
              onCancel: _exitSelectionMode,
            ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Received'),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(incomingRequestsCountProvider);
                        if (count > 0) {
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
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sent'),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(outgoingRequestsCountProvider);
                        if (count > 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: theme.colorScheme.onSecondary,
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
                _buildReceivedRequestsTab(context, theme, requestsState),
                _buildSentRequestsTab(context, theme, requestsState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    FriendRequestsState requestsState,
  ) {
    if (_isSelectionMode) {
      return AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer,
        leading: IconButton(
          onPressed: _exitSelectionMode,
          icon: const Icon(Icons.close),
        ),
        title: Text('${_selectedRequests.length} selected'),
        actions: [
          TextButton(
            onPressed: _selectedRequests.isNotEmpty 
              ? () => _handleBulkAction('accept')
              : null,
            child: const Text('Accept All'),
          ),
          TextButton(
            onPressed: _selectedRequests.isNotEmpty 
              ? () => _handleBulkAction('decline')
              : null,
            child: const Text('Decline All'),
          ),
        ],
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('Friend Requests'),
      actions: [
        if (requestsState.incomingRequests.isNotEmpty)
          TextButton(
            onPressed: _enterSelectionMode,
            child: const Text('Select'),
          ),
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'mark_all_read',
              child: const ListTile(
                leading: Icon(Icons.mark_email_read),
                title: Text('Mark All Read'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Request Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildReceivedRequestsTab(
    BuildContext context,
    ThemeData theme,
    FriendRequestsState requestsState,
  ) {
    if (requestsState.isLoading && requestsState.incomingRequests.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (requestsState.error != null && requestsState.incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading requests',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              requestsState.error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(friendRequestsControllerProvider.notifier).loadFriendRequests(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (requestsState.incomingRequests.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.person_add_disabled,
        title: 'No friend requests',
        subtitle: 'New friend requests will appear here',
        action: CustomButton(
          text: 'Find Friends',
          onPressed: () => Navigator.pushNamed(context, '/social/find-friends'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(friendRequestsControllerProvider.notifier).loadFriendRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requestsState.incomingRequests.length,
        itemBuilder: (context, index) {
          final request = requestsState.incomingRequests[index];
          
          return _buildIncomingRequestCard(context, theme, request);
        },
      ),
    );
  }

  Widget _buildIncomingRequestCard(BuildContext context, ThemeData theme, dynamic request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  request.senderName?.substring(0, 1).toUpperCase() ?? '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.senderName ?? 'Unknown User',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (request.message != null && request.message!.isNotEmpty)
                      Text(
                        request.message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptRequest(request.id),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _declineRequest(request.id),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestsTab(
    BuildContext context,
    ThemeData theme,
    FriendRequestsState requestsState,
  ) {
    if (requestsState.outgoingRequests.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.send,
        title: 'No sent requests',
        subtitle: 'Friend requests you send will appear here',
        action: CustomButton(
          text: 'Find Friends',
          onPressed: () => Navigator.pushNamed(context, '/social/find-friends'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requestsState.outgoingRequests.length,
      itemBuilder: (context, index) {
        final request = requestsState.outgoingRequests[index];
        
        return SentRequestCard(
          request: request,
          onCancel: () => _cancelRequest(request.id),
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

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRequests.clear();
    });
  }

  void _handleBulkAction(String action) async {
    if (_selectedRequests.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'accept' ? 'Accept' : 'Decline'} Requests'),
        content: Text(
          'Are you sure you want to $action ${_selectedRequests.length} friend requests?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'accept' ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (action == 'accept') {
        await ref.read(friendRequestsControllerProvider.notifier)
          .acceptMultipleRequests(_selectedRequests.toList());
      } else {
        await ref.read(friendRequestsControllerProvider.notifier)
          .declineMultipleRequests(_selectedRequests.toList());
      }
      _exitSelectionMode();
    }
  }

  void _acceptRequest(String requestId) {
    ref.read(friendRequestsControllerProvider.notifier).acceptFriendRequest(requestId);
  }

  void _declineRequest(String requestId) {
    ref.read(friendRequestsControllerProvider.notifier).declineFriendRequest(requestId);
  }

  void _cancelRequest(String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this friend request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(friendRequestsControllerProvider.notifier).cancelFriendRequest(requestId);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        ref.read(friendRequestsControllerProvider.notifier).markNotificationsAsRead();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All requests marked as read')),
        );
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings/friend-requests');
        break;
    }
  }
}
