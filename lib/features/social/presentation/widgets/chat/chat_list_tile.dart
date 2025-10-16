import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../utils/enums/social_enums.dart'; // For MessageType enum
import '../../../../../core/widgets/custom_avatar.dart';
import '../../../../../themes/app_colors.dart';
import '../../../../../themes/app_text_styles.dart';
import '../../../../../utils/formatters/time_formatter.dart';
import '../../../../../core/widgets/shimmer_loading.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/chat_message_model.dart';
import 'typing_indicator.dart';

/// A reusable list tile widget for displaying chat conversations
/// with preview, unread count, and status indicators
class ChatListTile extends ConsumerStatefulWidget {
  final ConversationModel conversation;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final bool isTyping;
  final List<String>? typingUsers;
  final bool isOnline;
  final bool isMuted;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(ConversationModel)? onPin;
  final Function(ConversationModel)? onMute;
  final Function(ConversationModel)? onDelete;
  final Function(ConversationModel)? onArchive;
  final EdgeInsetsGeometry? padding;
  final bool showOnlineStatus;

  const ChatListTile({
    super.key,
    required this.conversation,
    this.lastMessage,
    this.unreadCount = 0,
    this.isTyping = false,
    this.typingUsers,
    this.isOnline = false,
    this.isMuted = false,
    this.isPinned = false,
    this.onTap,
    this.onLongPress,
    this.onPin,
    this.onMute,
    this.onDelete,
    this.onArchive,
    this.padding,
    this.showOnlineStatus = true,
  });

  @override
  ConsumerState<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends ConsumerState<ChatListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Animate in
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    _showConversationOptions();
    widget.onLongPress?.call();
  }

  void _showConversationOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildOptionsSheet(),
    );
  }

  Widget _buildOptionsSheet() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _buildOptionTile(
            icon: widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            title: widget.isPinned ? 'Unpin Chat' : 'Pin Chat',
            onTap: () {
              Navigator.pop(context);
              widget.onPin?.call(widget.conversation);
            },
          ),
          _buildOptionTile(
            icon: widget.isMuted ? Icons.notifications : Icons.notifications_off,
            title: widget.isMuted ? 'Unmute' : 'Mute',
            onTap: () {
              Navigator.pop(context);
              widget.onMute?.call(widget.conversation);
            },
          ),
          _buildOptionTile(
            icon: Icons.archive_outlined,
            title: 'Archive',
            onTap: () {
              Navigator.pop(context);
              widget.onArchive?.call(widget.conversation);
            },
          ),
          _buildOptionTile(
            icon: Icons.delete_outline,
            title: 'Delete Chat',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete this chat with ${_getDisplayName()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call(widget.conversation);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    if (widget.conversation.isGroup) {
      return widget.conversation.name ?? 'Group Chat';
    }
    
    // For direct messages, show other participant's name
    final otherParticipant = widget.conversation.participants
        .firstWhere((p) => p.id != 'current_user', orElse: () => ConversationParticipant(
          id: '',
          name: 'Unknown',
          joinedAt: DateTime.now(),
        ));
    return otherParticipant.name;
  }

  String _getDisplayAvatar() {
    if (widget.conversation.isGroup) {
      return widget.conversation.avatarUrl ?? '';
    }
    final otherParticipant = widget.conversation.participants
        .firstWhere((p) => p.id != 'current_user', orElse: () => ConversationParticipant(
          id: '',
          name: 'Unknown',
          joinedAt: DateTime.now(),
        ));
    return otherParticipant.avatar;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: _isPressed
                    ? theme.highlightColor.withOpacity(0.1)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  onLongPress: _handleLongPress,
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildConversationInfo(),
                        ),
                        _buildTrailing(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CustomAvatar(
          imageUrl: _getDisplayAvatar(),
          radius: 28,
        ),
        if (widget.showOnlineStatus && !widget.conversation.isGroup) ...[
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
        if (widget.isPinned)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.push_pin,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _getDisplayName(),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: widget.unreadCount > 0 
                      ? FontWeight.bold 
                      : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isMuted)
              Icon(
                Icons.notifications_off,
                size: 16,
                color: AppColors.textSecondary,
              ),
          ],
        ),
        const SizedBox(height: 4),
        _buildLastMessagePreview(),
      ],
    );
  }

  Widget _buildLastMessagePreview() {
    if (widget.isTyping && widget.typingUsers != null) {
      return TypingIndicator(
        userNames: widget.typingUsers!,
        isCompact: true,
      );
    }

    if (widget.lastMessage == null) {
      return Text(
        'No messages yet',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final message = widget.lastMessage!;
    String previewText = _getMessagePreview(message);
    
    return Text(
      previewText,
      style: AppTextStyles.bodyMedium.copyWith(
        color: widget.unreadCount > 0 
            ? AppColors.textPrimary 
            : AppColors.textSecondary,
        fontWeight: widget.unreadCount > 0 
            ? FontWeight.w500 
            : FontWeight.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getMessagePreview(ChatMessageModel message) {
    final senderName = message.senderId == 'current_user' 
        ? 'You' 
        : (message.senderName.isNotEmpty ? message.senderName : 'Unknown');
    
    String content;
    switch (message.messageType) {
      case MessageType.text:
        content = message.content;
        break;
      case MessageType.image:
        content = '📷 Image';
        break;
      case MessageType.video:
        content = '🎥 Video';
        break;
      case MessageType.file:
        content = '📎 ${message.mediaAttachments.isNotEmpty ? message.mediaAttachments.first.name : 'File'}';
        break;
      case MessageType.audio:
        content = '🎵 Voice message';
        break;
      case MessageType.location:
        content = '📍 Location';
        break;
      case MessageType.gameInvite:
        content = '🎮 Game invite';
        break;
      case MessageType.system:
        content = message.content;
        break;
    }

    if (widget.conversation.isGroup) {
      return '$senderName: $content';
    }
    
    return content;
  }

  Widget _buildTrailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTimestamp(),
        const SizedBox(height: 4),
        _buildBadges(),
      ],
    );
  }

  Widget _buildTimestamp() {
    if (widget.lastMessage == null) {
      return const SizedBox.shrink();
    }

    return Text(
      TimeFormatter.format(widget.lastMessage!.sentAt),
      style: AppTextStyles.bodySmall.copyWith(
        color: widget.unreadCount > 0 
            ? AppColors.primary 
            : AppColors.textSecondary,
        fontWeight: widget.unreadCount > 0 
            ? FontWeight.w600 
            : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildBadges() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.unreadCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: widget.isMuted 
                  ? AppColors.textSecondary 
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              widget.unreadCount > 99 ? '99+' : widget.unreadCount.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ] else if (widget.lastMessage?.senderId == 'current_user') ...[
          Icon(
            _getMessageStatusIcon(),
            size: 16,
            color: _getMessageStatusColor(),
          ),
        ],
      ],
    );
  }

  IconData _getMessageStatusIcon() {
  // Status tracking not implemented; always return check icon
  return Icons.check;
  }

  Color _getMessageStatusColor() {
  // Status tracking not implemented; always return textSecondary
  return AppColors.textSecondary;
  }
}

/// Shimmer loading version for chat list
class ChatListTileShimmer extends StatelessWidget {
  const ChatListTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ShimmerLoading(
            height: 56,
            width: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ShimmerLoading(
                        height: 16,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShimmerLoading(
                      height: 12,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for smaller spaces
class CompactChatListTile extends StatelessWidget {
  final ConversationModel conversation;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final VoidCallback? onTap;

  const CompactChatListTile({
    super.key,
    required this.conversation,
    this.lastMessage,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChatListTile(
      conversation: conversation,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showOnlineStatus: false,
    );
  }
}
