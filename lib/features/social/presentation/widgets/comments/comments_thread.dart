import 'package:flutter/material.dart';
import 'package:dabbler/core/widgets/custom_avatar.dart';

class CommentsThread extends StatelessWidget {
  final dynamic comment;
  final Function(String)? onReply;
  final Function(String)? onLike;
  final Function(String)? onReport;
  final Function(String)? onDelete;
  final String postAuthorId;

  const CommentsThread({
    super.key,
    required this.comment,
    this.onReply,
    this.onLike,
    this.onReport,
    this.onDelete,
    required this.postAuthorId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnComment =
        comment.authorId ==
        'current_user_id'; // Replace with actual current user ID
    final isPostAuthor = comment.authorId == postAuthorId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment author avatar
          CustomAvatar(
            imageUrl: comment.author.avatar,
            radius: 16,
            fallbackIcon: Icons.person,
          ),

          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment header
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (isPostAuthor)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Author',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 10,
                          ),
                        ),
                      ),

                    const Spacer(),

                    Text(
                      _formatTime(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment text
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                ),

                const SizedBox(height: 8),

                // Comment actions
                Row(
                  children: [
                    _buildActionButton(
                      theme,
                      icon: comment.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: '${comment.likesCount}',
                      isActive: comment.isLiked,
                      onTap: () => onLike?.call(comment.id),
                      color: comment.isLiked ? Colors.red : null,
                    ),

                    const SizedBox(width: 16),

                    _buildActionButton(
                      theme,
                      icon: Icons.reply,
                      label: 'Reply',
                      onTap: () => onReply?.call(comment.id),
                    ),

                    const Spacer(),

                    // More options menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      itemBuilder: (context) => [
                        if (isOwnComment)
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.pop(context);
                                onDelete?.call(comment.id);
                              },
                            ),
                          )
                        else
                          PopupMenuItem<String>(
                            value: 'report',
                            child: ListTile(
                              leading: Icon(Icons.flag_outlined),
                              title: const Text('Report'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.pop(context);
                                onReport?.call(comment.id);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Replies
                if (comment.replies != null && comment.replies!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildReplies(theme),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  color ??
                  (isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplies(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: comment.replies!
            .map<Widget>((reply) => _buildReply(theme, reply))
            .toList(),
      ),
    );
  }

  Widget _buildReply(ThemeData theme, dynamic reply) {
    final isOwnReply =
        reply.authorId ==
        'current_user_id'; // Replace with actual current user ID

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomAvatar(
            imageUrl: reply.author.avatar,
            radius: 12,
            fallbackIcon: Icons.person,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.author.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(reply.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  reply.content,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    _buildActionButton(
                      theme,
                      icon: reply.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: '${reply.likesCount}',
                      isActive: reply.isLiked,
                      onTap: () => onLike?.call(reply.id),
                      color: reply.isLiked ? Colors.red : null,
                    ),

                    const SizedBox(width: 12),

                    _buildActionButton(
                      theme,
                      icon: Icons.reply,
                      label: 'Reply',
                      onTap: () => onReply?.call(reply.id),
                    ),

                    const Spacer(),

                    if (isOwnReply)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.pop(context);
                                onDelete?.call(reply.id);
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
