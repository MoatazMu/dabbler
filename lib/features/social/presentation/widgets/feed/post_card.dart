import 'package:flutter/material.dart';
import 'package:dabbler/data/models/social/post_model.dart';
import 'package:dabbler/features/social/services/social_service.dart';
import 'package:dabbler/core/widgets/custom_avatar.dart';

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
    return Opacity(
      opacity: isOptimistic ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: GestureDetector(
          onTap: onPostTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Row: Avatar + Display Name and Time + Post type badge + Overflow menu
              _buildHeader(context),

              const SizedBox(height: 12),

              // Second Row: Content + Media display
              _buildContent(context),

              // Third Row: vibe pill + Like action + Comment action
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        AppAvatar.small(
          imageUrl: post.authorAvatar,
          fallbackText: post.authorName,
          onTap: onProfileTap,
        ),

        const SizedBox(width: 12),

        // Display Name, Time, and Post type badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and time row
              Row(
                children: [
                  Text(
                    post.authorName,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '•',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(post.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Post type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPostTypeColor(colorScheme),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPostTypeLabel(),
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: _getPostTypeTextColor(colorScheme),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Overflow menu (hide/report)
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.more_horiz,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'hide',
              child: Row(
                children: [
                  Icon(Icons.visibility_off_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Hide Post'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Report'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'hide') {
              await _hidePost(context);
            } else if (value == 'report') {
              await _reportPost(context);
            }
          },
        ),
      ],
    );
  }

  String _getPostTypeLabel() {
    final kind = post.kind.toLowerCase();
    switch (kind) {
      case 'moment':
        return 'Moments';
      case 'dab':
        return 'Dab';
      case 'kickin':
        return 'Kick-in';
      default:
        return 'Moments';
    }
  }

  Color _getPostTypeColor(ColorScheme colorScheme) {
    final kind = post.kind.toLowerCase();
    switch (kind) {
      case 'moment':
        return colorScheme.primaryContainer.withOpacity(0.3);
      case 'dab':
        return colorScheme.secondaryContainer.withOpacity(0.3);
      case 'kickin':
        return colorScheme.tertiaryContainer.withOpacity(0.3);
      default:
        return colorScheme.primaryContainer.withOpacity(0.3);
    }
  }

  Color _getPostTypeTextColor(ColorScheme colorScheme) {
    final kind = post.kind.toLowerCase();
    switch (kind) {
      case 'moment':
        return colorScheme.primary;
      case 'dab':
        return colorScheme.secondary;
      case 'kickin':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
  }

  Widget _buildContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.content.isNotEmpty) ...[
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: _isRtl(post.content)
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                post.content,
                textDirection: _isRtl(post.content)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (post.mediaUrls.isNotEmpty) const SizedBox(height: 12),
        ],

        // Media display
        if (post.mediaUrls.isNotEmpty) _buildMediaContent(context),
      ],
    );
  }

  bool _isRtl(String text) {
    if (text.isEmpty) return false;
    final firstChar = text.trimLeft().codeUnitAt(0);
    // Arabic Unicode range: 0x0600 to 0x06FF
    // Arabic Supplement: 0x0750 to 0x077F
    // Arabic Extended-A: 0x08A0 to 0x08FF
    return (firstChar >= 0x0600 && firstChar <= 0x06FF) ||
        (firstChar >= 0x0750 && firstChar <= 0x077F) ||
        (firstChar >= 0x08A0 && firstChar <= 0x08FF);
  }

  Widget _buildMediaContent(BuildContext context) {
    final theme = Theme.of(context);

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
                  color: theme.colorScheme.surfaceContainerHighest,
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
                    color: theme.colorScheme.surfaceContainerHighest,
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
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          // Primary vibe pill - using default vibe for now
          // TODO: Join vibe data from public.vibes in feed query
          if (post.primaryVibeId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('😊', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(
                    'Amazed',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Like action
          _buildActionButton(
            context: context,
            emoji: post.isLiked ? '❤️' : '🩶',
            label: post.likesCount.toString(),
            isActive: post.isLiked,
            onTap: onLike,
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          // Comment action
          _buildActionButton(
            context: context,
            emoji: '💬',
            label: post.commentsCount.toString(),
            isActive: false,
            onTap: onComment,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String emoji,
    required String label,
    required bool isActive,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

extension on PostCard {
  Future<void> _hidePost(BuildContext context) async {
    try {
      await SocialService().hidePost(post.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post hidden')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to hide post: $e')));
    }
  }

  Future<void> _reportPost(BuildContext context) async {
    try {
      // Simple quick-report flow; use ThreadScreen dialog for detailed flow
      await SocialService().reportPost(
        postId: post.id,
        reason: 'Inappropriate content',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report submitted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to report: $e')));
    }
  }
}
