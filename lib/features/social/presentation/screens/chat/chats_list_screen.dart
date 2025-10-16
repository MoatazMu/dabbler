import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../providers/social_providers.dart';
import '../../widgets/chat/conversation_tile.dart';
import '../../widgets/chat/chat_search_bar.dart';
import '../../widgets/chat/archived_chats_banner.dart';
import '../../widgets/chat/pinned_chats_section.dart';
import '../../controllers/chat_controller.dart';
import '../../../data/models/conversation_model.dart';

class ChatsListScreen extends ConsumerStatefulWidget {
  const ChatsListScreen({super.key});

  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  bool _showSearchBar = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Load conversations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    ref.read(chatControllerProvider.notifier).searchConversations(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme, chatState),
      body: _buildBody(context, theme, chatState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewChat(),
        tooltip: 'New Chat',
        child: const Icon(Icons.message),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ChatState chatState,
  ) {
    if (_showSearchBar) {
      return AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          onPressed: () {
            setState(() {
              _showSearchBar = false;
              _searchController.clear();
            });
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: ChatSearchBar(
          controller: _searchController,
          autofocus: true,
          onChanged: (query) => _onSearchChanged(),
        ),
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const Text('Chats'),
          const SizedBox(width: 8),
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(totalUnreadMessagesProvider);
              if (unreadCount > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
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
      actions: [
        IconButton(
          onPressed: () {
            setState(() => _showSearchBar = true);
          },
          icon: const Icon(Icons.search),
          tooltip: 'Search',
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'new_group',
              child: const ListTile(
                leading: Icon(Icons.group_add),
                title: Text('New Group'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'archived_chats',
              child: ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Archived Chats'),
                subtitle: Consumer(
                  builder: (context, ref, child) {
                    final archivedCount = ref.watch(archivedChatsCountProvider);
                    return archivedCount > 0 
                      ? Text('$archivedCount chats')
                      : const SizedBox.shrink();
                  },
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'chat_settings',
              child: const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Chat Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'mark_all_read',
              child: const ListTile(
                leading: Icon(Icons.mark_email_read),
                title: Text('Mark All Read'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ChatState chatState) {
    if (chatState.isLoading && chatState.conversations.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (chatState.error != null && chatState.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              chatState.error!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(chatControllerProvider.notifier).loadConversations(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final conversations = _getFilteredConversations(chatState.conversations);
    final pinnedConversations = conversations.where((c) => c.isPinned).toList();
    final regularConversations = conversations.where((c) => !c.isPinned && !c.isArchived).toList();

    if (conversations.isEmpty && _searchQuery.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (conversations.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults(theme);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(chatControllerProvider.notifier).refreshConversations(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Archived chats banner
          Consumer(
            builder: (context, ref, child) {
              final archivedCount = ref.watch(archivedChatsCountProvider);
              if (archivedCount > 0) {
                return SliverToBoxAdapter(
                  child: ArchivedChatsBanner(
                    count: archivedCount,
                    onTap: () => _viewArchivedChats(),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Pinned chats section
          if (pinnedConversations.isNotEmpty && _searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: PinnedChatsSection(
                conversations: pinnedConversations,
                unreadCounts: chatState.unreadCounts,
                onConversationTap: (conversation) => _openConversation(conversation),
                onConversationAction: (conversation, action) => 
                  _handleConversationAction(conversation, action),
              ),
            ),

          // Regular conversations
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final conversation = regularConversations[index];
                
                return ConversationTile(
                  conversation: conversation,
                  onTap: () => _openConversation(conversation),
                  onLongPress: () => _showConversationOptions(conversation),
                  onSwipeArchive: () => _archiveConversation(conversation),
                  onSwipeDelete: () => _deleteConversation(conversation),
                  onSwipePin: () => _pinConversation(conversation),
                );
              },
              childCount: regularConversations.length,
            ),
          ),

          // Loading indicator
          if (chatState.isLoadingConversations)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: LoadingWidget()),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with your friends and teammates',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.message),
              label: const Text('Start New Chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No chats found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ConversationModel> _getFilteredConversations(List<dynamic> conversations) {
    if (_searchQuery.isEmpty) return conversations.cast<ConversationModel>();
    
    return conversations.where((conversation) {
      final name = conversation.name?.toLowerCase() ?? '';
      final lastMessage = conversation.lastMessage?.content?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || lastMessage.contains(query);
    }).cast<ConversationModel>().toList();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_group':
        Navigator.pushNamed(context, '/chat/new-group');
        break;
      case 'archived_chats':
        _viewArchivedChats();
        break;
      case 'chat_settings':
        Navigator.pushNamed(context, '/settings/chat');
        break;
      case 'mark_all_read':
        ref.read(chatControllerProvider.notifier).markAllConversationsRead();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All chats marked as read')),
        );
        break;
    }
  }

  void _startNewChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NewChatBottomSheet(
        onUserSelected: (userId) {
          Navigator.pop(context);
          _openChatWithUser(userId);
        },
        onCreateGroup: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/chat/new-group');
        },
      ),
    );
  }

  void _openConversation(dynamic conversation) {
    Navigator.pushNamed(
      context,
      '/chat/detail',
      arguments: {
        'conversationId': conversation.id,
        'conversation': conversation,
      },
    );
  }

  void _openChatWithUser(String userId) {
    Navigator.pushNamed(
      context,
      '/chat/detail',
      arguments: {'userId': userId},
    );
  }

  void _showConversationOptions(dynamic conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ConversationOptionsBottomSheet(
        conversation: conversation,
        onAction: (action) {
          Navigator.pop(context);
          _handleConversationAction(conversation, action);
        },
      ),
    );
  }

  void _handleConversationAction(dynamic conversation, String action) {
    switch (action) {
      case 'archive':
        _archiveConversation(conversation);
        break;
      case 'unarchive':
        _unarchiveConversation(conversation);
        break;
      case 'pin':
        _pinConversation(conversation);
        break;
      case 'unpin':
        _unpinConversation(conversation);
        break;
      case 'mute':
        _muteConversation(conversation);
        break;
      case 'unmute':
        _unmuteConversation(conversation);
        break;
      case 'delete':
        _deleteConversation(conversation);
        break;
      case 'mark_read':
        ref.read(chatControllerProvider.notifier).markConversationRead(conversation.id);
        break;
      case 'mark_unread':
        ref.read(chatControllerProvider.notifier).markConversationUnread(conversation.id);
        break;
    }
  }

  void _archiveConversation(dynamic conversation) {
    ref.read(chatControllerProvider.notifier).archiveConversation(conversation.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _unarchiveConversation(conversation),
        ),
      ),
    );
  }

  void _unarchiveConversation(dynamic conversation) {
    ref.read(chatControllerProvider.notifier).unarchiveConversation(conversation.id);
  }

  void _pinConversation(dynamic conversation) {
    ref.read(chatControllerProvider.notifier).pinConversation(conversation.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat pinned')),
    );
  }

  void _unpinConversation(dynamic conversation) {
    ref.read(chatControllerProvider.notifier).unpinConversation(conversation.id);
  }

  void _muteConversation(dynamic conversation) {
    showDialog(
      context: context,
      builder: (context) => MuteConversationDialog(
        onMute: (duration) {
          Navigator.pop(context);
          ref.read(chatControllerProvider.notifier)
            .muteConversation(conversation.id);
        },
      ),
    );
  }

  void _unmuteConversation(dynamic conversation) {
    ref.read(chatControllerProvider.notifier).unmuteConversation(conversation.id);
  }

  void _deleteConversation(dynamic conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat with ${conversation.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(chatControllerProvider.notifier).deleteConversation(conversation.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted')),
      );
    }
  }

  void _viewArchivedChats() {
    Navigator.pushNamed(context, '/chat/archived');
  }
}

/// New chat bottom sheet
class NewChatBottomSheet extends ConsumerWidget {
  final Function(String) onUserSelected;
  final VoidCallback onCreateGroup;

  const NewChatBottomSheet({
    super.key,
    required this.onUserSelected,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'New Chat',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.group_add),
                  ),
                  title: const Text('New Group'),
                  subtitle: const Text('Create a group chat'),
                  onTap: onCreateGroup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.qr_code_scanner),
                  ),
                  title: const Text('Scan QR Code'),
                  subtitle: const Text('Scan to start chat'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement QR code scanning
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Recent Chats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Recent contacts
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final friendsAsync = ref.watch(recentChatContactsProvider);
                
                return friendsAsync.when(
                  data: (friends) => ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: friend.avatarUrl != null 
                            ? NetworkImage(friend.avatarUrl!)
                            : null,
                          child: friend.avatarUrl == null 
                            ? Text(friend.displayName[0].toUpperCase())
                            : null,
                        ),
                        title: Text(friend.displayName),
                        subtitle: friend.lastActiveAt != null
                          ? const Text('Online', style: TextStyle(color: Colors.green))
                          : Text('Last seen ${friend.lastActiveAt ?? 'Unknown'}'),
                        trailing: friend.lastActiveAt != null
                          ? const Icon(Icons.circle, color: Colors.green, size: 12)
                          : null,
                        onTap: () => onUserSelected(friend.id),
                      );
                    },
                  ),
                  loading: () => const Center(child: LoadingWidget()),
                  error: (error, stack) => Center(
                    child: Text('Error loading contacts: $error'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Conversation options bottom sheet
class ConversationOptionsBottomSheet extends StatelessWidget {
  final dynamic conversation;
  final Function(String) onAction;

  const ConversationOptionsBottomSheet({
    super.key,
    required this.conversation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: conversation.avatar != null 
                  ? NetworkImage(conversation.avatar!)
                  : null,
                child: conversation.avatar == null 
                  ? Text(conversation.name[0].toUpperCase())
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (conversation.isGroup)
                      Text(
                        '${conversation.participantCount} participants',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Actions
          if (conversation.unreadCount > 0)
            _buildActionTile(
              icon: Icons.mark_email_read,
              title: 'Mark as read',
              onTap: () => onAction('mark_read'),
            )
          else
            _buildActionTile(
              icon: Icons.mark_email_unread,
              title: 'Mark as unread',
              onTap: () => onAction('mark_unread'),
            ),
          
          _buildActionTile(
            icon: conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            title: conversation.isPinned ? 'Unpin' : 'Pin',
            onTap: () => onAction(conversation.isPinned ? 'unpin' : 'pin'),
          ),
          
          _buildActionTile(
            icon: conversation.isMuted 
              ? Icons.notifications 
              : Icons.notifications_off,
            title: conversation.isMuted ? 'Unmute' : 'Mute',
            onTap: () => onAction(conversation.isMuted ? 'unmute' : 'mute'),
          ),
          
          _buildActionTile(
            icon: conversation.isArchived ? Icons.unarchive : Icons.archive,
            title: conversation.isArchived ? 'Unarchive' : 'Archive',
            onTap: () => onAction(conversation.isArchived ? 'unarchive' : 'archive'),
          ),
          
          const Divider(),
          
          _buildActionTile(
            icon: Icons.delete,
            title: 'Delete chat',
            onTap: () => onAction('delete'),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Mute conversation dialog
class MuteConversationDialog extends StatefulWidget {
  final Function(Duration) onMute;

  const MuteConversationDialog({
    super.key,
    required this.onMute,
  });

  @override
  State<MuteConversationDialog> createState() => _MuteConversationDialogState();
}

class _MuteConversationDialogState extends State<MuteConversationDialog> {
  Duration? _selectedDuration;

  final List<MapEntry<String, Duration>> _muteOptions = [
    MapEntry('15 minutes', Duration(minutes: 15)),
    MapEntry('1 hour', Duration(hours: 1)),
    MapEntry('8 hours', Duration(hours: 8)),
    MapEntry('24 hours', Duration(hours: 24)),
    MapEntry('Until I turn it back on', Duration(days: 365)),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mute notifications'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _muteOptions.map((option) {
          return RadioListTile<Duration>(
            value: option.value,
            groupValue: _selectedDuration,
            onChanged: (value) {
              setState(() => _selectedDuration = value);
            },
            title: Text(option.key),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedDuration != null 
            ? () => widget.onMute(_selectedDuration!)
            : null,
          child: const Text('Mute'),
        ),
      ],
    );
  }
}
