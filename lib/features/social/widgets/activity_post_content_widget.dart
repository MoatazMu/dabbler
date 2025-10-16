import 'package:flutter/material.dart';
import '../../../utils/enums/social_enums.dart';
import '../data/models/post_model.dart';

/// Widget that renders activity posts with activity-specific styling
/// Each activity type has a distinct colored border and icon
class ActivityPostContentWidget extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  
  const ActivityPostContentWidget({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activityType = _getActivityType();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activityType?.color ?? Colors.grey,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, activityType),
              const SizedBox(height: 12),
              _buildContent(theme),
              if (post.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMediaContent(),
              ],
              if (post.locationName != null) ...[
                const SizedBox(height: 8),
                _buildLocationChip(theme),
              ],
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTagsRow(theme),
              ],
              const SizedBox(height: 12),
              _buildEngagementSection(theme),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(ThemeData theme, PostActivityType? activityType) {
    return Row(
      children: [
        // Activity type icon with colored background
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: activityType?.color.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            activityType?.icon ?? Icons.post_add,
            color: activityType?.color ?? Colors.grey,
            size: 20,
          ),
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
                    post.authorName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (post.authorVerified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ],
                ],
              ),
              Text(
                '${activityType?.displayName ?? 'Posted'} • ${_formatTime(post.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        // More options menu
        Builder(
          builder: (BuildContext context) => IconButton(
            onPressed: () => _showOptionsMenu(context),
            icon: const Icon(Icons.more_vert),
            iconSize: 20,
          ),
        ),
      ],
    );
  }
  
  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.content,
          style: theme.textTheme.bodyMedium,
        ),
        if (_hasActivityData()) ...[
          const SizedBox(height: 8),
          _buildActivitySpecificContent(theme),
        ],
      ],
    );
  }
  
  Widget _buildActivitySpecificContent(ThemeData theme) {
    final activityType = _getActivityType();
    final activityData = post.activityData ?? {};
    
    switch (activityType) {
      case PostActivityType.venueRating:
        return _buildVenueRatingContent(theme, activityData);
      case PostActivityType.gameCreation:
      case PostActivityType.gameJoin:
        return _buildGameContent(theme, activityData);
      case PostActivityType.achievement:
        return _buildAchievementContent(theme, activityData);
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildVenueRatingContent(ThemeData theme, Map<String, dynamic> data) {
    final rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0;
    final review = data['review']?.toString();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '$rating/5.0',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          if (review != null && review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGameContent(ThemeData theme, Map<String, dynamic> data) {
    final gameType = data['gameType']?.toString() ?? '';
    final gameDateTime = data['gameDateTime']?.toString();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                gameType,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          if (gameDateTime != null) ...[
            const SizedBox(height: 4),
            Text(
              'Scheduled: ${DateTime.tryParse(gameDateTime)?.toLocal().toString().split('.')[0] ?? gameDateTime}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAchievementContent(ThemeData theme, Map<String, dynamic> data) {
    final achievementName = data['achievementName']?.toString() ?? '';
    final description = data['achievementDescription']?.toString();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.yellow[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievementName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700],
                  ),
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMediaContent() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: post.mediaUrls.length == 1
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.mediaUrls.first,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: post.mediaUrls.length,
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  post.mediaUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildLocationChip(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          post.locationName!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTagsRow(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: post.tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '#$tag',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildEngagementSection(ThemeData theme) {
    return Row(
      children: [
        _buildEngagementButton(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: post.likesCount.toString(),
          color: post.isLiked ? Colors.red : null,
          onPressed: onLike,
        ),
        const SizedBox(width: 16),
        _buildEngagementButton(
          icon: Icons.comment_outlined,
          label: post.commentsCount.toString(),
          onPressed: onComment,
        ),
        const SizedBox(width: 16),
        _buildEngagementButton(
          icon: Icons.share_outlined,
          label: post.sharesCount > 0 ? post.sharesCount.toString() : '',
          onPressed: onShare,
        ),
        const Spacer(),
        if (post.isBookmarked)
          Icon(
            Icons.bookmark,
            size: 20,
            color: theme.primaryColor,
          ),
      ],
    );
  }
  
  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  PostActivityType? _getActivityType() {
    if (post.activityType == null) return null;
    return PostActivityType.fromValue(post.activityType!);
  }
  
  bool _hasActivityData() {
    return post.activityData != null && post.activityData!.isNotEmpty;
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: Text(post.isBookmarked ? 'Remove bookmark' : 'Bookmark'),
              onTap: () {
                Navigator.of(context).pop();
                // Handle bookmark action
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                // Handle share action
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.of(context).pop();
                // Handle report action
              },
            ),
          ],
        ),
      ),
    );
  }
}
