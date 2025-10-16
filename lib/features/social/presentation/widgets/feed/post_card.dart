import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? VioletShades.darkBorder.withOpacity(0.5)
              : VioletShades.lightBorder,
          width: 1,
        ),
        color: isDark 
            ? VioletShades.darkCardBackground
            : VioletShades.lightCardBackground,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Row - Header
          _buildHeader(context),
          
          const SizedBox(height: 16),
          
          // Second Row - Content
          _buildContent(context),
          
          const SizedBox(height: 16),
          
          // Third Row - Actions
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // First Column - Avatar, Name, Time
          Expanded(
            child: Row(
              children: [
                // User Avatar
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: post.authorAvatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(post.authorAvatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: post.authorAvatar.isEmpty
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: Border.all(
                        color: isDark 
                            ? VioletShades.darkBorder.withOpacity(0.3)
                            : VioletShades.lightBorder,
                        width: 2,
                      ),
                    ),
                    child: post.authorAvatar.isEmpty
                        ? Center(
                            child: Text(
                              post.authorName.isNotEmpty
                                  ? post.authorName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Name and Time
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          color: isDark 
                              ? VioletShades.darkTextPrimary
                              : VioletShades.lightTextPrimary,
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: isDark 
                              ? VioletShades.darkTextMuted
                              : VioletShades.lightTextMuted,
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Second Column - More Icon
          IconButton(
            onPressed: () {
              // TODO: Show post options
            },
            icon: Icon(
              Iconsax.more_copy,
              size: 24,
              color: isDark 
                  ? VioletShades.darkTextMuted
                  : VioletShades.lightTextMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post Text
        Text(
          post.content,
          style: TextStyle(
            color: isDark 
                ? VioletShades.darkTextPrimary
                : VioletShades.lightTextPrimary,
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        
        // Media if available
        if (post.mediaUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMediaContent(context),
        ],
      ],
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (post.mediaUrls.isEmpty) return const SizedBox.shrink();
    
    final mediaUrl = post.mediaUrls.first;
    final isVideo = mediaUrl.contains('.mp4') || 
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
        // Like Button with Count
        _ActionButton(
          icon: post.isLiked ? Iconsax.heart : Iconsax.heart_copy,
          iconColor: post.isLiked 
              ? const Color(0xFFFF6B6B) 
              : (isDark ? VioletShades.darkTextMuted : VioletShades.lightTextMuted),
          count: post.likesCount,
          textColor: isDark ? VioletShades.darkTextMuted : VioletShades.lightTextMuted,
          onTap: onLike,
        ),
        
        const SizedBox(width: 24),
        
        // Comment Button with Count
        _ActionButton(
          icon: Iconsax.message_copy,
          iconColor: isDark ? VioletShades.darkTextMuted : VioletShades.lightTextMuted,
          count: post.commentsCount,
          textColor: isDark ? VioletShades.darkTextMuted : VioletShades.lightTextMuted,
          onTap: onComment,
        ),
        
        const Spacer(),
        
        // Share Button
        IconButton(
          onPressed: onShare,
          icon: Icon(
            Iconsax.share_copy,
            size: 20,
            color: isDark ? VioletShades.darkTextMuted : VioletShades.lightTextMuted,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
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

/// Action button widget for post interactions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int count;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
