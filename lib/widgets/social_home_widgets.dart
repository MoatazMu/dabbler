import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants/route_constants.dart';

/// Social widgets to be integrated into the home screen
class SocialHomeWidgets {
  
  /// Friend activity summary widget
  static Widget friendActivitySummary(BuildContext context) {
    return _SocialSectionCard(
      title: 'Friend Activity',
      icon: LucideIcons.users,
      onViewAll: () => context.push(RoutePaths.socialFeed),
      child: Column(
        children: [
          _ActivityItem(
            avatar: 'https://i.pravatar.cc/150?img=1',
            name: 'Sarah Chen',
            action: 'joined a basketball game',
            time: '2 hours ago',
            onTap: () => context.push('/social/profile/sarah'),
          ),
          _ActivityItem(
            avatar: 'https://i.pravatar.cc/150?img=2',
            name: 'Mike Johnson',
            action: 'shared a post about tennis',
            time: '4 hours ago',
            onTap: () => context.push('/social/profile/mike'),
          ),
          _ActivityItem(
            avatar: 'https://i.pravatar.cc/150?img=3',
            name: 'Alex Rivera',
            action: 'created a new game',
            time: '6 hours ago',
            onTap: () => context.push('/social/profile/alex'),
          ),
        ],
      ),
    );
  }

  /// Recent posts preview widget
  static Widget recentPostsPreview(BuildContext context) {
    return _SocialSectionCard(
      title: 'Recent Posts',
      icon: LucideIcons.messageSquare,
      onViewAll: () => context.push(RoutePaths.socialFeed),
      child: Column(
        children: [
          _PostPreviewItem(
            author: 'Emma Wilson',
            avatar: 'https://i.pravatar.cc/150?img=4',
            content: 'Great tennis match today at Central Courts! Looking for partners for next week.',
            likes: 12,
            comments: 3,
            time: '1 hour ago',
            onTap: () => context.push('/social/post/post1'),
          ),
          const Divider(height: 1),
          _PostPreviewItem(
            author: 'David Kim',
            avatar: 'https://i.pravatar.cc/150?img=5',
            content: 'New to the area and looking for basketball buddies. Anyone know good courts nearby?',
            likes: 8,
            comments: 5,
            time: '3 hours ago',
            onTap: () => context.push('/social/post/post2'),
          ),
        ],
      ),
    );
  }

  /// Unread messages count widget
  static Widget unreadMessagesCount(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Replace with actual unread count from social services
        const unreadCount = 3;
        
        if (unreadCount == 0) return const SizedBox.shrink();
        
        return GestureDetector(
          onTap: () => context.push(RoutePaths.socialChatList),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'You have $unreadCount unread messages',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Friend suggestions widget
  static Widget friendSuggestions(BuildContext context) {
    return _SocialSectionCard(
      title: 'People You May Know',
      icon: LucideIcons.userPlus,
      onViewAll: () => context.push(RoutePaths.socialFriends),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: 5,
          itemBuilder: (context, index) => _FriendSuggestionCard(
            name: _mockNames[index],
            avatar: 'https://i.pravatar.cc/150?img=${index + 10}',
            mutualFriends: index + 1,
            onAdd: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Friend request sent to ${_mockNames[index]}')),
              );
            },
            onTap: () => context.push('/social/profile/user${index + 10}'),
          ),
        ),
      ),
    );
  }

  /// Trending in network widget
  static Widget trendingInNetwork(BuildContext context) {
    return _SocialSectionCard(
      title: 'Trending in Your Network',
      icon: LucideIcons.trendingUp,
      onViewAll: () => context.push(RoutePaths.socialFeed),
      child: Column(
        children: [
          _TrendingItem(
            icon: LucideIcons.gamepad2,
            title: 'Basketball',
            description: '15 friends are playing this week',
            trending: true,
            onTap: () => context.push('/games?sport=basketball'),
          ),
          _TrendingItem(
            icon: LucideIcons.mapPin,
            title: 'Central Sports Complex',
            description: '8 friends visited recently',
            trending: false,
            onTap: () => context.push('/venues/central-sports'),
          ),
          _TrendingItem(
            icon: LucideIcons.users,
            title: 'Tennis Group Chat',
            description: '12 new messages',
            trending: true,
            onTap: () => context.push('/social/chat/tennis-group'),
          ),
        ],
      ),
    );
  }

  // TODO: Replace with real friend suggestions from FriendsRepository.getFriendSuggestions()
  // This widget needs to be converted to use Riverpod and fetch real data
  static const List<String> _mockNames = [
    'No suggestions available',
  ];
}

class _SocialSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onViewAll;

  const _SocialSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String avatar;
  final String name;
  final String action;
  final String time;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.avatar,
    required this.name,
    required this.action,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(avatar),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' $action'),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _PostPreviewItem extends StatelessWidget {
  final String author;
  final String avatar;
  final String content;
  final int likes;
  final int comments;
  final String time;
  final VoidCallback onTap;

  const _PostPreviewItem({
    required this.author,
    required this.avatar,
    required this.content,
    required this.likes,
    required this.comments,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(avatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.heart, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$likes', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(LucideIcons.messageCircle, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$comments', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendSuggestionCard extends StatelessWidget {
  final String name;
  final String avatar;
  final int mutualFriends;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const _FriendSuggestionCard({
    required this.name,
    required this.avatar,
    required this.mutualFriends,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatar),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$mutualFriends mutual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool trending;
  final VoidCallback onTap;

  const _TrendingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.trending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (trending) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TRENDING',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
