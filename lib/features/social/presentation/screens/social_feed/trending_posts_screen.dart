import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as core_widgets;
import '../../providers/social_providers.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/trending/trending_filter_bar.dart';
import '../../widgets/trending/trending_hashtags_widget.dart';
import '../../widgets/trending/top_contributors_widget.dart';
import '../../widgets/trending/engagement_metrics_widget.dart';

class TrendingPostsScreen extends ConsumerStatefulWidget {
  const TrendingPostsScreen({super.key});

  @override
  ConsumerState<TrendingPostsScreen> createState() => _TrendingPostsScreenState();
}

class _TrendingPostsScreenState extends ConsumerState<TrendingPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  TrendingCategory _selectedCategory = TrendingCategory.all;
  TrendingTimeRange _selectedTimeRange = TrendingTimeRange.today;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Load initial trending posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrendingPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreTrendingPosts();
    }
  }

  void _loadTrendingPosts() {
    ref.read(socialFeedControllerProvider.notifier).loadTrendingPosts(
      category: _selectedCategory,
      timeRange: _selectedTimeRange,
    );
  }

  void _loadMoreTrendingPosts() {
    ref.read(socialFeedControllerProvider.notifier).loadMoreTrendingPosts();
  }

  Future<void> _onRefresh() async {
    await ref.read(socialFeedControllerProvider.notifier).refreshTrendingPosts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: Column(
        children: [
          // Filter bar
          TrendingFilterBar(
            selectedCategory: _selectedCategory,
            selectedTimeRange: _selectedTimeRange,
            onCategoryChanged: (category) {
              setState(() => _selectedCategory = category);
              _loadTrendingPosts();
            },
            onTimeRangeChanged: (timeRange) {
              setState(() => _selectedTimeRange = timeRange);
              _loadTrendingPosts();
            },
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Hashtags'),
              Tab(text: 'Contributors'),
              Tab(text: 'Metrics'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrendingPosts(context, theme),
                _buildTrendingHashtags(context, theme),
                _buildTopContributors(context, theme),
                _buildEngagementMetrics(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: const Text('Trending'),
      actions: [
        IconButton(
          onPressed: _showTrendingInfo,
          icon: const Icon(Icons.info_outline),
          tooltip: 'How trending works',
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share_trending',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share Trending'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'customize',
              child: ListTile(
                leading: Icon(Icons.tune),
                title: Text('Customize'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildTrendingPosts(BuildContext context, ThemeData theme) {
    final trendingState = ref.watch(socialFeedControllerProvider);
    
    if (trendingState.isLoading && trendingState.trendingPosts.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (trendingState.error != null && trendingState.trendingPosts.isEmpty) {
      return Center(
        child: core_widgets.ErrorWidget(
          message: trendingState.error!,
          onRetry: _loadTrendingPosts,
        ),
      );
    }

    if (trendingState.trendingPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No trending posts',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for trending content',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: trendingState.trendingPosts.length + 1,
        itemBuilder: (context, index) {
          if (index >= trendingState.trendingPosts.length) {
            // Show loading indicator or end message
            if (trendingState.hasMoreTrending && trendingState.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: LoadingWidget()),
              );
            }
            
            if (!trendingState.hasMoreTrending && trendingState.trendingPosts.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'You\'ve seen all trending posts',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            
            return const SizedBox.shrink();
          }
          
          final post = trendingState.trendingPosts[index];
          
          return Column(
            children: [
              // Trending rank indicator
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${index + 1} Trending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${post.likesCount} likes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Post card
              PostCard(
                post: post,
                onLike: () => _handlePostLike(post.id),
                onComment: () => _navigateToPostDetail(post.id),
                onShare: () => _handlePostShare(post),
                onPostTap: () => _navigateToPostDetail(post.id),
                onProfileTap: () => _navigateToProfile(post.authorId),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrendingHashtags(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final hashtagsAsync = ref.watch(trendingHashtagsProvider(_selectedTimeRange));
        
        return hashtagsAsync.when(
          data: (hashtags) => TrendingHashtagsWidget(
            hashtags: hashtags,
            onHashtagTap: () => _navigateToHashtag("trending"),
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: core_widgets.ErrorWidget(
              message: error.toString(),
              onRetry: () => ref.refresh(trendingHashtagsProvider(_selectedTimeRange)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopContributors(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final contributorsAsync = ref.watch(topContributorsProvider(_selectedTimeRange));
        
        return contributorsAsync.when(
          data: (contributors) => TopContributorsWidget(
            contributors: contributors,
            onContributorTap: (userId) => _navigateToProfile(userId),
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: core_widgets.ErrorWidget(
              message: error.toString(),
              onRetry: () => ref.refresh(topContributorsProvider(_selectedTimeRange)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEngagementMetrics(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final metricsAsync = ref.watch(engagementMetricsProvider(_selectedTimeRange));
        
        return metricsAsync.when(
          data: (metrics) => EngagementMetricsWidget(
            metrics: metrics,
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: core_widgets.ErrorWidget(
              message: error.toString(),
              onRetry: () => ref.refresh(engagementMetricsProvider(_selectedTimeRange)),
            ),
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share_trending':
        _shareTrendingPage();
        break;
      case 'customize':
        _showCustomizeDialog();
        break;
    }
  }

  void _showTrendingInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Trending Works'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trending posts are calculated based on:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Recent engagement (likes, comments, shares)'),
              Text('• Rate of engagement growth'),
              Text('• Post recency'),
              Text('• Author influence'),
              Text('• Community relevance'),
              SizedBox(height: 16),
              Text(
                'Time Ranges:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Today: Last 24 hours'),
              Text('• This Week: Last 7 days'),
              Text('• This Month: Last 30 days'),
              Text('• All Time: Best performing posts'),
              SizedBox(height: 16),
              Text(
                'Categories help filter trending content by sport or topic to show you what\'s most relevant.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCustomizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Trending'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Show trending scores'),
              subtitle: const Text('Display engagement metrics on posts'),
              value: true, // Get from settings
              onChanged: (value) {
                // Update settings
              },
            ),
            CheckboxListTile(
              title: const Text('Personalized trending'),
              subtitle: const Text('Show trending content based on your interests'),
              value: true, // Get from settings
              onChanged: (value) {
                // Update settings
              },
            ),
            CheckboxListTile(
              title: const Text('Hide seen posts'),
              subtitle: const Text('Don\'t show posts you\'ve already interacted with'),
              value: false, // Get from settings
              onChanged: (value) {
                // Update settings
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Save settings
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _shareTrendingPage() {
    // Implement sharing trending page
    // Share URL
  }

  void _handlePostLike(String postId) {
    ref.read(socialFeedControllerProvider.notifier).reactToPost(
      postId, 
      'like',
    );
  }

  void _handlePostShare(dynamic post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
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

  void _navigateToHashtag(String hashtag) {
    Navigator.pushNamed(
      context,
      '/social/hashtag',
      arguments: {'hashtag': hashtag},
    );
  }
}
