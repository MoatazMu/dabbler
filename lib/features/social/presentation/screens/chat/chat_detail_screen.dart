import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as core_error_widget;
import '../../providers/social_providers.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_input_widget.dart';
import '../../widgets/chat/typing_indicator.dart' as chat_typing_indicator;
// import '../../widgets/chat/date_separator.dart'; // File not found
// import '../../widgets/chat/chat_app_bar.dart'; // File not found
import '../../controllers/chat_controller.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  String? _conversationId;
  String? _userId;
  dynamic _conversation;
  dynamic _replyToMessage;
  
  bool _isAtBottom = true;
  bool _showScrollToBottomFab = false;
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    _scrollController.addListener(_onScrollChanged);
    _messageController.addListener(_onMessageChanged);
    _focusNode.addListener(_onFocusChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractArguments();
      _loadConversationData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed && _conversationId != null) {
      // Mark conversation as read when app becomes active
      ref.read(chatControllerProvider.notifier).markConversationRead(_conversationId!);
    }
  }

  void _extractArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _conversationId = args['conversationId'] as String?;
      _userId = args['userId'] as String?;
      _conversation = args['conversation'];
    }
  }

  void _loadConversationData() {
    if (_conversationId != null) {
      ref.read(chatControllerProvider.notifier).loadMessages(_conversationId!);
      ref.read(chatControllerProvider.notifier).markConversationRead(_conversationId!);
    } else if (_userId != null) {
      ref.read(chatControllerProvider.notifier).getOrCreateConversation(_userId!);
    }
  }

  void _onScrollChanged() {
    final isAtBottom = _scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 100;
    
    if (isAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        _showScrollToBottomFab = !isAtBottom;
      });
      
      if (_showScrollToBottomFab) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }

    // Load more messages when scrolled to top
    if (_scrollController.position.pixels == 0) {
      _loadMoreMessages();
    }
  }

  void _onMessageChanged() {
    final isTyping = _messageController.text.isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() => _isTyping = isTyping);
      
      if (_conversationId != null) {
        ref.read(chatControllerProvider.notifier)
          .updateTypingStatus(_conversationId!, isTyping);
      }
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _conversationId != null) {
      // Mark as read when focused
      ref.read(chatControllerProvider.notifier).markConversationRead(_conversationId!);
    }
  }

  void _loadMoreMessages() {
    if (_conversationId != null) {
      ref.read(chatControllerProvider.notifier).loadMoreMessages(_conversationId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme, chatState),
      body: _buildBody(context, theme, chatState),
      floatingActionButton: _buildScrollToBottomFab(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ChatState chatState,
  ) {
  // ChatAppBar widget not found. Please implement or remove this usage.
  return AppBar();
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ChatState chatState) {
    if (chatState.isLoadingMessages && chatState.messages.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return Center(
        child: core_error_widget.ErrorWidget(
          message: chatState.error!,
          onRetry: () => _loadConversationData(),
        ),
      );
    }

    final messages = _getMessagesForConversation(chatState.messages);
    final conversation = _conversation ?? _getCurrentConversation(chatState);

    return Column(
      children: [
        // Messages list
        Expanded(
          child: _buildMessagesList(context, theme, messages, conversation, chatState),
        ),
        
        // Typing indicator
        _buildTypingIndicator(conversation, chatState),
        
        // Message input
        _buildMessageInput(context, theme, conversation, chatState),
      ],
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    ThemeData theme,
    List<dynamic> messages,
    dynamic conversation,
    ChatState chatState,
  ) {
    if (messages.isEmpty) {
      return _buildEmptyMessages(theme, conversation);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (chatState.isLoadingMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at top
        if (index == messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: LoadingWidget()),
          );
        }

        final message = messages[index];

        return Column(
          children: [
            // Date separator
            // DateSeparator widget not found. Please implement or remove this usage.
            if (_shouldShowDateSeparator(message, index < messages.length - 1 ? messages[index + 1] : null))
              const SizedBox.shrink(),

            // Message bubble
            ChatBubble(
              message: message,
              onReply: () => _setReplyToMessage(message),
              onReact: () => _reactToMessage(message, '👍'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyMessages(ThemeData theme, dynamic conversation) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: conversation?.avatar != null 
                ? NetworkImage(conversation.avatar!)
                : null,
              child: conversation?.avatar == null 
                ? Icon(
                    conversation?.isGroup == true ? Icons.group : Icons.person,
                    size: 32,
                  )
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              conversation?.name ?? 'Unknown',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              conversation?.isGroup == true
                ? 'Start chatting in this group'
                : 'Send your first message',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (conversation?.isGroup == true && conversation?.description != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  conversation.description,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(dynamic conversation, ChatState chatState) {
    if (conversation == null || !_hasTypingUsers(conversation, chatState)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: chat_typing_indicator.TypingIndicator(
        userNames: _getTypingUserNames(conversation, chatState),
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    ThemeData theme,
    dynamic conversation,
    ChatState chatState,
  ) {
    return ChatInputWidget(
      controller: _messageController,
      focusNode: _focusNode,
      replyToMessage: _replyToMessage,
      onSendText: (content) => _sendMessage(content, []),
      onSendVoice: (audioUrl) => _sendVoiceMessage(audioUrl, Duration.zero),
      onCancelReply: () => _cancelReply(),
      onAttachmentTap: () => _showAttachmentOptions(),
    );
  }

  Widget _buildScrollToBottomFab() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.small(
            onPressed: _scrollToBottom,
            child: const Icon(Icons.keyboard_arrow_down),
          ),
        );
      },
    );
  }

  List<dynamic> _getMessagesForConversation(List<dynamic> allMessages) {
    if (_conversationId != null) {
      return allMessages.where((m) => m.conversationId == _conversationId).toList();
    }
    return allMessages;
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

  bool _shouldShowDateSeparator(dynamic message, dynamic previousMessage) {
    if (previousMessage == null) return true;
    
    final messageDate = DateTime.parse(message.timestamp);
    final previousDate = DateTime.parse(previousMessage.timestamp);
    
    return messageDate.day != previousDate.day ||
           messageDate.month != previousDate.month ||
           messageDate.year != previousDate.year;
  }

  bool _hasTypingUsers(dynamic conversation, ChatState chatState) {
    return _getTypingUserNames(conversation, chatState).isNotEmpty;
  }

  List<String> _getTypingUserNames(dynamic conversation, ChatState chatState) {
    // Filter typing users for this conversation and return names
    final typingUsers = chatState.typingUsers.where((user) => 
      user.userId == conversation?.id
    ).toList();
    
    return typingUsers.map((user) => user.userName).toList();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage(String content, List<dynamic> attachments) async {
    if (content.trim().isEmpty && attachments.isEmpty) return;
    
    final messageContent = content.trim();
    _messageController.clear();
    
    if (_conversationId != null) {
      await ref.read(chatControllerProvider.notifier).sendMessage(
        _conversationId!,
        messageContent,
        attachments: attachments,
        replyToId: _replyToMessage?.id,
      );
    } else if (_userId != null) {
      // Create conversation and send message
      final conversationId = await ref.read(chatControllerProvider.notifier)
        .getOrCreateConversation(_userId!);
      
      if (conversationId != null) {
        _conversationId = conversationId;
        await ref.read(chatControllerProvider.notifier).sendMessage(
          conversationId,
          messageContent,
          attachments: attachments,
          replyToId: _replyToMessage?.id,
        );
      }
    }
    
    _cancelReply();
    _scrollToBottom();
  }

  void _sendVoiceMessage(String audioPath, Duration duration) async {
    if (_conversationId != null) {
      await ref.read(chatControllerProvider.notifier).sendVoiceMessage(
        _conversationId!,
        audioPath,
        duration,
        replyToId: _replyToMessage?.id,
      );
    }
    
    _cancelReply();
    _scrollToBottom();
  }

  void _setReplyToMessage(dynamic message) {
    setState(() => _replyToMessage = message);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyToMessage = null);
  }

  void _reactToMessage(dynamic message, String reaction) {
    ref.read(chatControllerProvider.notifier).reactToMessage(
      message.id,
      reaction,
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentOptionsBottomSheet(
        onTakePicture: () {
          Navigator.pop(context);
          _takePicture();
        },
        onPickImage: () {
          Navigator.pop(context);
          _pickImage();
        },
        onPickVideo: () {
          Navigator.pop(context);
          _pickVideo();
        },
        onPickFile: () {
          Navigator.pop(context);
          _pickFile();
        },
        onPickLocation: () {
          Navigator.pop(context);
          _pickLocation();
        },
        onPickContact: () {
          Navigator.pop(context);
          _pickContact();
        },
      ),
    );
  }

  void _takePicture() {
    // TODO: Implement camera capture
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature coming soon')),
    );
  }

  void _pickImage() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker feature coming soon')),
    );
  }

  void _pickVideo() {
    // TODO: Implement video picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video picker feature coming soon')),
    );
  }

  void _pickFile() {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker feature coming soon')),
    );
  }

  void _pickLocation() {
    // TODO: Implement location picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location picker feature coming soon')),
    );
  }

  void _pickContact() {
    // TODO: Implement contact picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact picker feature coming soon')),
    );
  }

}

/// Attachment options bottom sheet
class AttachmentOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onTakePicture;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickFile;
  final VoidCallback onPickLocation;
  final VoidCallback onPickContact;

  const AttachmentOptionsBottomSheet({
    super.key,
    required this.onTakePicture,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickFile,
    required this.onPickLocation,
    required this.onPickContact,
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
              Text(
                'Send Attachment',
                style: theme.textTheme.titleMedium?.copyWith(
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
          
          // Attachment options grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.red,
                onTap: onTakePicture,
              ),
              _buildAttachmentOption(
                icon: Icons.photo,
                label: 'Gallery',
                color: Colors.purple,
                onTap: onPickImage,
              ),
              _buildAttachmentOption(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.orange,
                onTap: onPickVideo,
              ),
              _buildAttachmentOption(
                icon: Icons.insert_drive_file,
                label: 'Document',
                color: Colors.blue,
                onTap: onPickFile,
              ),
              _buildAttachmentOption(
                icon: Icons.location_on,
                label: 'Location',
                color: Colors.green,
                onTap: onPickLocation,
              ),
              _buildAttachmentOption(
                icon: Icons.person,
                label: 'Contact',
                color: Colors.teal,
                onTap: onPickContact,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
