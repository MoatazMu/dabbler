import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../themes/app_theme.dart';
import '../../providers/social_providers.dart';
import 'post_media_widget.dart';
import 'social_sharing_widget.dart';

class PostCard extends ConsumerStatefulWidget {
  final dynamic post;
  final bool showComments;
  final VoidCallback? onTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMenuTap;

  const PostCard({
    super.key,
    required this.post,
    this.showComments = false,
    this.onTap,
    this.onCommentTap,
    this.onShareTap,
    this.onMenuTap,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _showFullContent = false;
  final int _maxLines = 3;

  @override
  void initState() {
    super.initState();
    
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _likeAnimation = CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isDark ? 4 : 2,
        shadowColor: isDark 
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark 
                ? VioletShades.darkBorder.withOpacity(0.3)
                : VioletShades.lightBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: _handleDoubleTap,
          onTapDown: (_) => _scaleAnimationController.forward(),
          onTapUp: (_) => _scaleAnimationController.reverse(),
          onTapCancel: () => _scaleAnimationController.reverse(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark 
                  ? VioletShades.darkCardBackground
                  : VioletShades.lightCardBackground,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author header
                    _buildAuthorHeader(context, theme),
                    
                    // Post content
                    _buildPostContent(context, theme),
                    
                    // Post media
                    if (widget.post.media != null && widget.post.media.isNotEmpty)
                      _buildPostMedia(context, theme),
                    
                    // Game result card
                    if (widget.post.type == 'game_result')
                      _buildGameResultCard(context, theme),
                    
                    // Achievement badge
                    if (widget.post.type == 'achievement')
                      _buildAchievementBadge(context, theme),
                    
                    // Engagement bar
                    _buildEngagementBar(context, theme),
                    
                    // Comments section
                    if (widget.showComments)
                      _buildCommentsSection(context, theme),
                  ],
                ),
                
                // Like animation overlay
                _buildLikeAnimationOverlay(),
                
                // Reaction picker overlay
                _buildReactionPickerOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.post.author?.avatar != null 
              ? NetworkImage(widget.post.author.avatar!)
              : null,
            child: widget.post.author?.avatar == null 
              ? Text(
                  widget.post.author?.name?[0]?.toUpperCase() ?? '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
          ),
          
          const SizedBox(width: 12),
          
          // Author info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.author?.name ?? 'Unknown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.post.author?.isVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                    if (widget.post.isSponsored == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sponsored',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(widget.post.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.post.location != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.post.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Menu button
          IconButton(
            onPressed: widget.onMenuTap ?? () => _showPostMenu(context),
            icon: const Icon(Icons.more_vert),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, ThemeData theme) {
    if (widget.post.content?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    final content = widget.post.content!;
    final hasLongContent = content.length > 200 || content.split('\n').length > _maxLines;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: theme.textTheme.bodyMedium,
            maxLines: _showFullContent ? null : _maxLines,
            overflow: _showFullContent ? null : TextOverflow.ellipsis,
          ),
          if (hasLongContent) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _showFullContent = !_showFullContent);
              },
              child: Text(
                _showFullContent ? 'Show less' : 'Read more',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPostMedia(BuildContext context, ThemeData theme) {
    return PostMediaWidget(
      media: widget.post.media,
      onMediaTap: (index) => _openMediaViewer(index),
      onMediaDoubleTap: _handleDoubleTap,
    );
  }

  Widget _buildGameResultCard(BuildContext context, ThemeData theme) {
    final gameData = widget.post.gameData;
    if (gameData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_esports,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Game Result',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            gameData['gameName'] ?? 'Unknown Game',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Score: '),
              Text(
                '${gameData['score'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (gameData['duration'] != null)
                Text('Duration: ${gameData['duration']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(BuildContext context, ThemeData theme) {
    final achievement = widget.post.achievement;
    if (achievement == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.2),
            Colors.orange.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievement Unlocked!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievement['name'] ?? 'Unknown Achievement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (achievement['description'] != null)
                  Text(
                    achievement['description'],
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Simple like button (no reaction picker)
          GestureDetector(
            onTap: () => _handleReaction('like'),
            child: _buildEngagementButton(
              icon: widget.post.currentUserReaction != null
                ? _getReactionIcon(widget.post.currentUserReaction)
                : Icons.favorite_border,
              label: _formatCount(widget.post.likeCount ?? 0),
              isActive: widget.post.currentUserReaction != null,
              color: widget.post.currentUserReaction != null
                ? _getReactionColor(widget.post.currentUserReaction)
                : null,
              onTap: () => _handleQuickLike(),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Comment button
          _buildEngagementButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(widget.post.commentCount ?? 0),
            onTap: widget.onCommentTap ?? () => _openComments(),
          ),
          
          const SizedBox(width: 16),
          
          // Share button
          _buildEngagementButton(
            icon: Icons.share_outlined,
            label: _formatCount(widget.post.shareCount ?? 0),
            onTap: widget.onShareTap ?? () => _showShareOptions(context),
          ),
          
          const Spacer(),
          
          // Bookmark button
          IconButton(
            onPressed: () => _toggleBookmark(),
            icon: Icon(
              widget.post.isBookmarked == true
                ? Icons.bookmark
                : Icons.bookmark_border,
            ),
            color: widget.post.isBookmarked == true
              ? theme.colorScheme.primary
              : null,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final buttonColor = color ?? (isActive ? theme.colorScheme.primary : null);
    
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: buttonColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: buttonColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
        
        return commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Container(
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: comments.take(3).map((comment) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      comment.content,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingWidget(),
          ),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildLikeAnimationOverlay() {
    return AnimatedBuilder(
      animation: _likeAnimation,
      builder: (context, child) {
        if (_likeAnimation.value == 0) {
          return const SizedBox.shrink();
        }
        
        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Transform.scale(
                scale: _likeAnimation.value,
                child: Opacity(
                  opacity: 1 - _likeAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 50,
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

  Widget _buildReactionPickerOverlay() {
    // This will be handled by the ReactionPicker widget
    return const SizedBox.shrink();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reset();
    });
    _handleQuickLike();
  }

  void _handleQuickLike() {
    ref.read(socialFeedControllerProvider.notifier).togglePostLike(widget.post.id);
  }

  void _handleReaction(String reaction) {
    ref.read(socialFeedControllerProvider.notifier).reactToPost(
      widget.post.id,
      reaction,
    );
  }

  void _toggleBookmark() {
    ref.read(socialFeedControllerProvider.notifier).togglePostBookmark(widget.post.id);
  }

  void _openComments() {
    Navigator.pushNamed(
      context,
      '/post/comments',
      arguments: {'postId': widget.post.id},
    );
  }

  void _openMediaViewer(int index) {
    Navigator.pushNamed(
      context,
      '/media-viewer',
      arguments: {
        'media': widget.post.media,
        'initialIndex': index,
      },
    );
  }
  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PostMenuBottomSheet(
        post: widget.post,
        onEdit: () => _editPost(),
        onDelete: () => _deletePost(),
        onReport: () => _reportPost(),
        onHide: () => _hidePost(),
        onCopyLink: () => _copyPostLink(),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SocialSharingWidget(
        post: widget.post,
        onShare: (platform) => _shareToSocialPlatform(platform),
        onCopyLink: () => _copyPostLink(),
        onShareViaChat: () => _shareViaChat(),
        onCreateStory: () => _createStoryFromPost(),
      ),
    );
  }

  void _editPost() {
    Navigator.pushNamed(
      context,
      '/post/edit',
      arguments: {'post': widget.post},
    );
  }

  void _deletePost() {
    ref.read(socialFeedControllerProvider.notifier).deletePost(widget.post.id);
  }

  void _reportPost() {
    Navigator.pushNamed(
      context,
      '/report/post',
      arguments: {'postId': widget.post.id},
    );
  }

  void _hidePost() {
    ref.read(socialFeedControllerProvider.notifier).hidePost(widget.post.id);
  }

  void _copyPostLink() {
    final link = 'https://dabbler.app/post/${widget.post.id}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _shareToSocialPlatform(String platform) {
  }

  void _shareViaChat() {
    Navigator.pushNamed(
      context,
      '/chat/share',
      arguments: {'post': widget.post},
    );
  }

  void _createStoryFromPost() {
    Navigator.pushNamed(
      context,
      '/story/create',
      arguments: {'sourcePost': widget.post},
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  IconData _getReactionIcon(String reaction) {
    switch (reaction) {
      case 'like':
        return Icons.favorite;
      case 'love':
        return Icons.favorite;
      case 'laugh':
        return Icons.sentiment_very_satisfied;
      case 'wow':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.favorite;
    }
  }

  Color _getReactionColor(String reaction) {
    switch (reaction) {
      case 'like':
      case 'love':
        return Colors.red;
      case 'laugh':
        return Colors.orange;
      case 'wow':
        return Colors.blue;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      default:
        return Colors.red;
    }
  }
}

/// Post menu bottom sheet
class PostMenuBottomSheet extends StatelessWidget {
  final dynamic post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onHide;
  final VoidCallback? onCopyLink;

  const PostMenuBottomSheet({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onHide,
    this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnPost = post.isOwnPost ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Post Options',
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
          
          if (isOwnPost) ...[
            _buildMenuTile(
              icon: Icons.edit,
              title: 'Edit post',
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            _buildMenuTile(
              icon: Icons.delete,
              title: 'Delete post',
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
              isDestructive: true,
            ),
          ] else ...[
            _buildMenuTile(
              icon: Icons.visibility_off,
              title: 'Hide this post',
              onTap: () {
                Navigator.pop(context);
                onHide?.call();
              },
            ),
            _buildMenuTile(
              icon: Icons.report,
              title: 'Report post',
              onTap: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
          ],
          
          _buildMenuTile(
            icon: Icons.link,
            title: 'Copy link',
            onTap: () {
              Navigator.pop(context);
              onCopyLink?.call();
            },
          ),
          
          _buildMenuTile(
            icon: Icons.bookmark_border,
            title: 'Save post',
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
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
