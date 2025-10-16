import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as custom_error;
import '../../../providers/social_providers.dart';
import '../../widgets/chat/participant_tile.dart';
import '../../widgets/chat/media_grid.dart';
import '../../widgets/chat/chat_info_section.dart';
import '../../controllers/chat_controller.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  ConsumerState<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String? _conversationId;
  dynamic _conversation;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractArguments();
      _loadChatSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _extractArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _conversationId = args['conversationId'] as String?;
      _conversation = args['conversation'];
    }
  }

  void _loadChatSettings() {
    if (_conversationId != null) {
      ref.read(chatControllerProvider.notifier).loadConversationDetails(_conversationId!);
      ref.read(chatControllerProvider.notifier).loadConversationMedia(_conversationId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: _buildBody(context, theme, chatState),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('Chat Info'),
      actions: [
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit_chat',
              child: const ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'export_chat',
              child: const ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'share_chat',
              child: const ListTile(
                leading: Icon(Icons.share),
                title: Text('Share Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Media'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ChatState chatState) {
    if (chatState.isLoadingConversations && _conversation == null) {
      return const Center(child: LoadingWidget());
    }

    if (chatState.error != null && _conversation == null) {
      return Center(
        child: custom_error.ErrorWidget(
          message: chatState.error!,
          onRetry: () => _loadChatSettings(),
        ),
      );
    }

    final conversation = _conversation ?? _getCurrentConversation(chatState);
    
    if (conversation == null) {
      return const Center(
        child: Text('Conversation not found'),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildDetailsTab(context, theme, conversation, chatState),
        _buildMediaTab(context, theme, conversation, chatState),
        _buildSettingsTab(context, theme, conversation, chatState),
      ],
    );
  }

  Widget _buildDetailsTab(
    BuildContext context,
    ThemeData theme,
    dynamic conversation,
    ChatState chatState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chat info section
          ChatInfoSection(
            conversation: conversation,
            onEditName: () => _editChatName(conversation),
            onEditDescription: () => _editChatDescription(conversation),
            onEditAvatar: () => _editChatAvatar(conversation),
          ),
          
          const SizedBox(height: 24),
          
          // Participants section (for group chats)
          if (conversation.isGroup) ...[
            Row(
              children: [
                Text(
                  'Participants',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addParticipants(conversation),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Consumer(
              builder: (context, ref, child) {
                final participants = ref.watch(conversationParticipantsProvider(_conversationId!));
                
                return participants.when(
                  data: (participantList) => Column(
                    children: participantList.map((participant) {
                      return ParticipantTile(
                        participant: participant,
                        isAdmin: participant.isAdmin,
                        canManage: _canManageParticipants(conversation),
                        onTap: () => _viewParticipantProfile(participant),
                        onMakeAdmin: () => _makeAdmin(participant),
                        onRemoveAdmin: () => _removeAdmin(participant),
                        onRemove: () => _removeParticipant(participant),
                      );
                    }).toList(),
                  ),
                  loading: () => const LoadingWidget(),
                  error: (error, stack) => Text('Error loading participants: $error'),
                );
              },
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Shared media preview
          _buildSharedMediaPreview(theme, conversation, chatState),
          
          const SizedBox(height: 24),
          
          // Chat statistics
          _buildChatStatistics(theme, conversation, chatState),
          
          const SizedBox(height: 24),
          
          // Quick actions
          _buildQuickActions(theme, conversation),
        ],
      ),
    );
  }

  Widget _buildMediaTab(
    BuildContext context,
    ThemeData theme,
    dynamic conversation,
    ChatState chatState,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final media = ref.watch(conversationMediaProvider(_conversationId!));
        
        return media.when(
          data: (mediaList) {
            if (mediaList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No media shared yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Photos, videos, and files will appear here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return MediaGrid(
              media: mediaList,
              onMediaTap: (media) => _openMediaViewer(media),
              onMediaLongPress: (media) => _showMediaOptions(media),
            );
          },
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: custom_error.ErrorWidget(
              message: 'Error loading media: $error',
              onRetry: () => ref.refresh(conversationMediaProvider(_conversationId!)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(
    BuildContext context,
    ThemeData theme,
    dynamic conversation,
    ChatState chatState,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Notification settings
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              Consumer(
                builder: (context, ref, child) {
                  final isMuted = conversation.isMuted ?? false;
                  
                  return SwitchListTile(
                    title: const Text('Mute notifications'),
                    subtitle: Text(isMuted ? 'Notifications are muted' : 'Get notified for new messages'),
                    value: isMuted,
                    onChanged: (value) => _toggleMute(conversation, value),
                  );
                },
              ),
              
              ListTile(
                title: const Text('Custom notification'),
                subtitle: const Text('Set custom sound and vibration'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _customizeNotifications(conversation),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Privacy settings
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Privacy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              if (conversation.isGroup) ...[
                Consumer(
                  builder: (context, ref, child) {
                    final readReceipts = conversation.readReceiptsEnabled ?? true;
                    
                    return SwitchListTile(
                      title: const Text('Read receipts'),
                      subtitle: const Text('Show when messages are read'),
                      value: readReceipts,
                      onChanged: (value) => _toggleReadReceipts(conversation, value),
                    );
                  },
                ),
                
                Consumer(
                  builder: (context, ref, child) {
                    final allowInvites = conversation.allowMemberInvites ?? true;
                    
                    return SwitchListTile(
                      title: const Text('Allow member invites'),
                      subtitle: const Text('Let members add new participants'),
                      value: allowInvites,
                      onChanged: (value) => _toggleMemberInvites(conversation, value),
                    );
                  },
                ),
              ],
              
              ListTile(
                title: const Text('Encryption info'),
                subtitle: const Text('Messages are end-to-end encrypted'),
                leading: const Icon(Icons.lock),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEncryptionInfo(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chat management
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chat Management',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              ListTile(
                title: const Text('Clear chat history'),
                subtitle: const Text('Delete all messages in this chat'),
                leading: const Icon(Icons.clear_all),
                onTap: () => _clearChatHistory(conversation),
              ),
              
              if (conversation.isGroup && _isAdmin(conversation)) ...[
                ListTile(
                  title: const Text('Delete group'),
                  subtitle: const Text('Permanently delete this group for everyone'),
                  leading: Icon(Icons.delete, color: theme.colorScheme.error),
                  onTap: () => _deleteGroup(conversation),
                ),
              ] else if (!conversation.isGroup) ...[
                ListTile(
                  title: const Text('Block user'),
                  subtitle: const Text('Block this user and delete chat'),
                  leading: Icon(Icons.block, color: theme.colorScheme.error),
                  onTap: () => _blockUser(conversation),
                ),
              ] else ...[
                ListTile(
                  title: const Text('Leave group'),
                  subtitle: const Text('Leave this group chat'),
                  leading: Icon(Icons.exit_to_app, color: theme.colorScheme.error),
                  onTap: () => _leaveGroup(conversation),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSharedMediaPreview(ThemeData theme, dynamic conversation, ChatState chatState) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Shared Media',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          
          Consumer(
            builder: (context, ref, child) {
              // TODO: Implement recentConversationMediaProvider
              const recentMedia = AsyncValue.data(<dynamic>[]);
              
              return recentMedia.when(
                data: (mediaList) {
                  if (mediaList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No shared media'),
                    );
                  }
                  
                  return Container(
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mediaList.length,
                      itemBuilder: (context, index) {
                        final media = mediaList[index];
                        
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Media thumbnail
                                if (media.type == 'image')
                                  Image.network(
                                    media.thumbnailUrl ?? media.url,
                                    fit: BoxFit.cover,
                                  )
                                else if (media.type == 'video')
                                  Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        media.thumbnailUrl ?? media.url,
                                        fit: BoxFit.cover,
                                      ),
                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Center(
                                    child: Icon(
                                      _getFileIcon(media.type),
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                
                                // Tap overlay
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openMediaViewer(media),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: LoadingWidget()),
                ),
                error: (error, stack) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Error loading media'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatStatistics(ThemeData theme, dynamic conversation, ChatState chatState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Consumer(
              builder: (context, ref, child) {
                // TODO: Implement conversationStatsProvider
                final mockStats = {
                  'totalMessages': 0, 
                  'mediaCount': 0, 
                  'participantCount': 0,
                  'createdDate': DateTime.now(),
                };
                final stats = AsyncValue.data(mockStats);
                
                return stats.when(
                  data: (statsData) => Column(
                    children: [
                      _buildStatRow('Messages', '${statsData['totalMessages']}'),
                      _buildStatRow('Media shared', '${statsData['mediaCount']}'),
                      _buildStatRow('Created', _formatDate(statsData['createdDate'] as DateTime?)),
                      if (conversation.isGroup)
                        _buildStatRow('Members', '${statsData['memberCount']}'),
                    ],
                  ),
                  loading: () => const LoadingWidget(),
                  error: (error, stack) => const Text('Unable to load statistics'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, dynamic conversation) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search in chat'),
            onTap: () => _searchInChat(conversation),
          ),
          
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Starred messages'),
            onTap: () => _viewStarredMessages(conversation),
          ),
          
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export chat'),
            onTap: () => _exportChat(conversation),
          ),
        ],
      ),
    );
  }

  dynamic _getCurrentConversation(ChatState chatState) {
    if (_conversation != null) return _conversation;
    if (_conversationId != null) {
      try {
        return chatState.conversations.firstWhere(
          (c) => c.id == _conversationId,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool _canManageParticipants(dynamic conversation) {
    // Check if current user is admin or has permission to manage participants
    return conversation.isGroup && _isAdmin(conversation);
  }

  bool _isAdmin(dynamic conversation) {
    // Check if current user is admin of the group
    return conversation.currentUserRole == 'admin';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else {
      return 'Today';
    }
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit_chat':
        _editChatInfo();
        break;
      case 'export_chat':
        _exportChat(_conversation);
        break;
      case 'share_chat':
        _shareChat(_conversation);
        break;
    }
  }

  void _editChatInfo() {
    // TODO: Implement edit chat info
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit chat info feature coming soon')),
    );
  }

  void _editChatName(dynamic conversation) {
    showDialog(
      context: context,
      builder: (context) => _EditChatNameDialog(
        currentName: conversation.name,
        onSave: (newName) {
          ref.read(chatControllerProvider.notifier)
            .updateConversationName(_conversationId!, newName);
        },
      ),
    );
  }

  void _editChatDescription(dynamic conversation) {
    showDialog(
      context: context,
      builder: (context) => _EditChatDescriptionDialog(
        currentDescription: conversation.description ?? '',
        onSave: (newDescription) {
          ref.read(chatControllerProvider.notifier)
            .updateConversationDescription(_conversationId!, newDescription);
        },
      ),
    );
  }

  void _editChatAvatar(dynamic conversation) {
    // TODO: Implement edit chat avatar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit avatar feature coming soon')),
    );
  }

  void _addParticipants(dynamic conversation) {
    Navigator.pushNamed(
      context,
      '/chat/add-participants',
      arguments: {'conversationId': _conversationId},
    );
  }

  void _viewParticipantProfile(dynamic participant) {
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userId': participant.id},
    );
  }

  void _makeAdmin(dynamic participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Admin'),
        content: Text('Make ${participant.name} a group admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Make Admin'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(chatControllerProvider.notifier)
        .makeParticipantAdmin(_conversationId!, participant.id);
    }
  }

  void _removeAdmin(dynamic participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Remove ${participant.name} as group admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(chatControllerProvider.notifier)
        .removeParticipantAdmin(_conversationId!, participant.id);
    }
  }

  void _removeParticipant(dynamic participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Participant'),
        content: Text('Remove ${participant.name} from the group?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(chatControllerProvider.notifier)
        .removeParticipant(_conversationId!, participant.id);
    }
  }

  void _openMediaViewer(dynamic media) {
    Navigator.pushNamed(
      context,
      '/media-viewer',
      arguments: {'media': media},
    );
  }

  void _showMediaOptions(dynamic media) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement download
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement share
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement delete media
            },
          ),
        ],
      ),
    );
  }

  void _toggleMute(dynamic conversation, bool value) {
    if (value) {
      ref.read(chatControllerProvider.notifier).muteConversation(_conversationId!);
    } else {
      ref.read(chatControllerProvider.notifier).unmuteConversation(_conversationId!);
    }
  }

  void _customizeNotifications(dynamic conversation) {
    // TODO: Implement custom notifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom notifications feature coming soon')),
    );
  }

  void _toggleReadReceipts(dynamic conversation, bool value) {
    ref.read(chatControllerProvider.notifier)
      .updateReadReceiptsEnabled(_conversationId!, value);
  }

  void _toggleMemberInvites(dynamic conversation, bool value) {
    ref.read(chatControllerProvider.notifier)
      .updateMemberInvitesEnabled(_conversationId!, value);
  }

  void _showEncryptionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encryption Info'),
        content: const Text(
          'Messages in this chat are secured with end-to-end encryption. '
          'Only you and the participants in this chat have the keys to read these messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearChatHistory(dynamic conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all messages in this chat? '
          'This action cannot be undone.',
        ),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(chatControllerProvider.notifier).clearChatHistory(_conversationId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    }
  }

  void _deleteGroup(dynamic conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? '
          'This will permanently delete the group for all members.',
        ),
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
      ref.read(chatControllerProvider.notifier).deleteConversation(_conversationId!);
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _blockUser(dynamic conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Block ${conversation.name}? You won\'t receive messages from them.',
        ),
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
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement block user
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _leaveGroup(dynamic conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Leave ${conversation.name}?'),
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(chatControllerProvider.notifier).leaveConversation(_conversationId!);
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _searchInChat(dynamic conversation) {
    Navigator.pushNamed(
      context,
      '/chat/search',
      arguments: {'conversationId': _conversationId},
    );
  }

  void _viewStarredMessages(dynamic conversation) {
    Navigator.pushNamed(
      context,
      '/chat/starred',
      arguments: {'conversationId': _conversationId},
    );
  }

  void _exportChat(dynamic conversation) {
    // TODO: Implement export chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export chat feature coming soon')),
    );
  }

  void _shareChat(dynamic conversation) {
    // TODO: Implement share chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share chat feature coming soon')),
    );
  }
}

/// Edit chat name dialog
class _EditChatNameDialog extends StatefulWidget {
  final String currentName;
  final Function(String) onSave;

  const _EditChatNameDialog({
    required this.currentName,
    required this.onSave,
  });

  @override
  State<_EditChatNameDialog> createState() => _EditChatNameDialogState();
}

class _EditChatNameDialogState extends State<_EditChatNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Chat Name'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Chat name',
          border: OutlineInputBorder(),
        ),
        maxLength: 50,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newName = _controller.text.trim();
            if (newName.isNotEmpty && newName != widget.currentName) {
              widget.onSave(newName);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Edit chat description dialog
class _EditChatDescriptionDialog extends StatefulWidget {
  final String currentDescription;
  final Function(String) onSave;

  const _EditChatDescriptionDialog({
    required this.currentDescription,
    required this.onSave,
  });

  @override
  State<_EditChatDescriptionDialog> createState() => _EditChatDescriptionDialogState();
}

class _EditChatDescriptionDialogState extends State<_EditChatDescriptionDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Description'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Group description',
          border: OutlineInputBorder(),
        ),
        maxLength: 200,
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newDescription = _controller.text.trim();
            widget.onSave(newDescription);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
