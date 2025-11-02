import 'package:flutter/material.dart';

import '../../../data/models/post_model.dart';
import '../../../../../themes/app_theme.dart';

/// A card widget for displaying social posts in the feed
class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onPostTap;
  final VoidCallback? onProfileTap;
  final bool isOptimistic;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onPostTap,
    this.onProfileTap,
    this.isOptimistic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: isOptimistic ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? VioletShades.darkCardBackground
              : VioletShades.lightCardBackground,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? VioletShades.darkBorder.withOpacity(0.2)
                  : VioletShades.lightBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Display Name & Time
            _buildHeader(context),

            const SizedBox(height: 12),

            // Content
            _buildContent(context),

            const SizedBox(height: 12),

            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // User Avatar
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: post.authorAvatar.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(post.authorAvatar),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: post.authorAvatar.isEmpty
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : null,
            ),
            child: post.authorAvatar.isEmpty
                ? Center(
                    child: Text(
                      post.authorName.isNotEmpty
                          ? post.authorName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
        ),

        const SizedBox(width: 12),

        // Display Name and Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name from Database
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.authorName,
                      style: TextStyle(
                        color: isDark
                            ? VioletShades.darkTextPrimary
                            : VioletShades.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.authorVerified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    '· ${_formatTimeAgo(post.createdAt)}',
                    style: TextStyle(
                      color: isDark
                          ? VioletShades.darkTextMuted
                          : VioletShades.lightTextMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // More Icon
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_horiz,
            size: 20,
            color: isDark
                ? VioletShades.darkTextMuted.withOpacity(0.6)
                : VioletShades.lightTextMuted.withOpacity(0.6),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.content.isNotEmpty) ...[
          Text(
            post.content,
            style: TextStyle(
              color: isDark
                  ? VioletShades.darkTextPrimary
                  : VioletShades.lightTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Media display
        if (post.mediaUrls.isNotEmpty) _buildMediaContent(context),
      ],
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (post.mediaUrls.isEmpty) return const SizedBox.shrink();

    final mediaUrl = post.mediaUrls.first;
    final isVideo =
        mediaUrl.contains('.mp4') ||
        mediaUrl.contains('.mov') ||
        mediaUrl.contains('.avi');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: isVideo
            ? Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? VioletShades.darkWidgetBackground
                      : VioletShades.lightWidgetBackground,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.primary,
                      size: 40,
                    ),
                  ),
                ),
              )
            : Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: isDark
                        ? VioletShades.darkWidgetBackground
                        : VioletShades.lightWidgetBackground,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark
                        ? VioletShades.darkWidgetBackground
                        : VioletShades.lightWidgetBackground,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: isDark
                          ? VioletShades.darkTextMuted
                          : VioletShades.lightTextMuted,
                      size: 48,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        _buildActionButton(
          context: context,
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: post.likesCount.toString(),
          isActive: post.isLiked,
          isDark: isDark,
          onTap: onLike,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          context: context,
          icon: Icons.chat_bubble_outline,
          label: post.commentsCount.toString(),
          isActive: false,
          isDark: isDark,
          onTap: onComment,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          context: context,
          icon: Icons.repeat,
          label: post.sharesCount.toString(),
          isActive: false,
          isDark: isDark,
          onTap: onShare,
        ),
        const Spacer(),
        _buildActionButton(
          context: context,
          icon: Icons.bookmark_border,
          label: '',
          isActive: false,
          isDark: isDark,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isActive
                  ? theme.colorScheme.primary
                  : (isDark
                        ? VioletShades.darkTextMuted.withOpacity(0.7)
                        : VioletShades.lightTextMuted.withOpacity(0.7)),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? theme.colorScheme.primary
                      : (isDark
                            ? VioletShades.darkTextMuted
                            : VioletShades.lightTextMuted),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
