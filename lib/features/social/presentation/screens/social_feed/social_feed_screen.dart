import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as core;
import '../../../../../utils/enums/social_enums.dart';
import '../../providers/social_providers.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/feed/feed_filter_chips.dart';
import '../../widgets/feed/empty_feed_widget.dart';
import '../../controllers/social_feed_controller.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialFeedControllerProvider.notifier).loadPosts();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      ref.read(socialFeedControllerProvider.notifier).loadMorePosts();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(socialFeedControllerProvider.notifier).refreshFeed();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final feedState = ref.watch(socialFeedControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: _buildBody(context, theme, feedState),
      floatingActionButton: _buildFloatingActionButton(context, theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Text(
            'Feed',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Navigate to search
              Navigator.pushNamed(context, '/social/search');
            },
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              // Navigate to notifications
              Navigator.pushNamed(context, '/social/notifications');
            },
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final hasNotifications = ref.watch(hasNotificationsProvider);
                    if (!hasNotifications) return const SizedBox.shrink();
                    
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, SocialFeedState feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return Center(
        child: core.ErrorWidget(
          message: feedState.error!,
          onRetry: () => ref.read(socialFeedControllerProvider.notifier).loadPosts(),
        ),
      );
    }

    if (feedState.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: const EmptyFeedWidget(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Stories section placeholder (temporarily disabled)
          // const SliverToBoxAdapter(
          //   child: StoriesSection(),
          // ),
          
          // Filter chips
          SliverToBoxAdapter(
            child: FeedFilterChips(
              currentFilter: feedState.filter,
              onFilterChanged: (filter) {
                ref.read(socialFeedControllerProvider.notifier).changeFilter(filter);
              },
            ),
          ),
          
          // Error banner if there's an error but we have posts
          if (feedState.error != null && feedState.posts.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load new posts. Pull to refresh.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(socialFeedControllerProvider.notifier).clearError();
                      },
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Posts list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final posts = feedState.filteredPosts;
                
                if (index >= posts.length) {
                  // Show loading indicator at bottom
                  if (feedState.hasMore && feedState.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: LoadingWidget()),
                    );
                  }
                  
                  // Show "no more posts" message
                  if (!feedState.hasMore && posts.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'You\'ve seen all posts',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return const SizedBox.shrink();
                }
                
                final post = posts[index];
                
                return PostCard(
                  post: post,
                  onLike: () => _handlePostLike(post.id),
                  onComment: () => _navigateToPostDetail(post.id),
                  onShare: () => _handlePostShare(post),
                  onPostTap: () => _navigateToPostDetail(post.id),
                  onProfileTap: () => _navigateToProfile(post.authorId),
                  isOptimistic: feedState.optimisticPosts.contains(post.id),
                );
              },
              childCount: feedState.filteredPosts.length + 1, // +1 for loading indicator
            ),
          ),
          
          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final hasPendingPosts = ref.watch(hasPendingPostsProvider);
        
        return Stack(
          children: [
            FloatingActionButton(
              onPressed: () => _navigateToCreatePost(),
              tooltip: 'Create Post',
              child: const Icon(Icons.add),
            ),
            
            // Show indicator if there are pending posts
            if (hasPendingPosts)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _handlePostLike(String postId) {
    ref.read(socialFeedControllerProvider.notifier).reactToPost(
      postId, 
      ReactionType.like.name,
    );
  }

  void _handlePostShare(dynamic post) {
    // Show share bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => SharePostBottomSheet(post: post),
    );
  }

  void _navigateToPostDetail(String postId) {
    Navigator.pushNamed(
      context,
      '/social/post-detail',
      arguments: {'postId': postId},
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userId': userId},
    );
  }

  void _navigateToCreatePost() {
    Navigator.pushNamed(context, '/social/create-post');
  }
}

/// Share post bottom sheet
class SharePostBottomSheet extends StatelessWidget {
  final dynamic post;

  const SharePostBottomSheet({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Share Post',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          _buildShareOption(
            context,
            icon: Icons.copy,
            title: 'Copy Link',
            onTap: () => _copyLink(context),
          ),
          
          _buildShareOption(
            context,
            icon: Icons.message,
            title: 'Share via Message',
            onTap: () => _shareViaMessage(context),
          ),
          
          _buildShareOption(
            context,
            icon: Icons.more_horiz,
            title: 'More Options',
            onTap: () => _showMoreOptions(context),
          ),
          
          const SizedBox(height: 10),
          
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _copyLink(BuildContext context) {
    // Implement copy link functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _shareViaMessage(BuildContext context) {
    // Navigate to message sharing
    Navigator.pushNamed(context, '/social/share-message', arguments: post);
  }

  void _showMoreOptions(BuildContext context) {
    // Show platform-specific share options
  }
}
