import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/themes/app_theme.dart';

class FriendsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const FriendsListWidget({
    super.key,
    required this.friends,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No friends yet',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Friends (${friends.length})',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (friends.length > 6 && onViewAll != null)
                TextButton(onPressed: onViewAll, child: const Text('View All')),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: friends.length > 6 ? 6 : friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _FriendAvatarItem(friend: friend);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FriendAvatarItem extends StatelessWidget {
  final Map<String, dynamic> friend;

  const _FriendAvatarItem({required this.friend});

  @override
  Widget build(BuildContext context) {
    final userId = friend['user_id'] as String? ?? friend['id'] as String?;
    final displayName = friend['display_name'] as String? ?? 'User';
    final avatarUrl = friend['avatar_url'] as String?;
    final verified = friend['verified'] as bool? ?? false;

    return GestureDetector(
      onTap: () {
        if (userId != null) {
          context.push('/user-profile/$userId');
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            displayName.substring(0, 1).toUpperCase(),
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                ),
                if (verified)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayName.length > 10
                  ? '${displayName.substring(0, 10)}...'
                  : displayName,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
