import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/core/design_system/layouts/two_section_layout.dart';
import '../widgets/feed/post_card.dart';
import 'package:dabbler/widgets/thoughts_input.dart';
import 'package:dabbler/data/models/social/post_model.dart';
import '../../services/social_service.dart';
import '../../services/social_rewards_handler.dart';
import 'package:dabbler/core/services/auth_service.dart';

/// Instagram-like social feed screen with posts and interactions
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final List<PostModel> _posts = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  // Removed search functionality – simplified feed

  late SocialRewardsHandler _rewardsHandler;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _rewardsHandler = SocialRewardsHandler();
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final socialService = SocialService();
      final posts = await socialService.getFeedPosts();

      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _isLoading = false;
      });
    } catch (e) {
      // Show error, don't fall back to sample data
      setState(() {
        _posts.clear();
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to load posts: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ignore: unused_element
  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  void _likePost(String postId) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return;

    try {
      final socialService = SocialService();
      await socialService.toggleLike(postId);

      // Track social interaction for rewards
      final post = _posts.firstWhere((p) => p.id == postId);
      await _rewardsHandler.trackSocialInteraction(
        userId: currentUser.id,
        interactionType: 'like',
        targetUserId: post.authorId,
        metadata: {'postId': postId},
      );

      // Update UI optimistically
      setState(() {
        final postIndex = _posts.indexWhere((post) => post.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          _posts[postIndex] = post.copyWith(
            isLiked: !post.isLiked,
            likesCount: post.isLiked
                ? post.likesCount - 1
                : post.likesCount + 1,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('Failed to update like'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openComments(String postId) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      // Track comment interaction for rewards
      _rewardsHandler.trackSocialInteraction(
        userId: currentUser.id,
        interactionType: 'comment',
        targetUserId: _posts.firstWhere((p) => p.id == postId).authorId,
        metadata: {'postId': postId},
      );
    }

    // Navigate to PostDetailScreen to view and add comments
    context.push('/social-post-detail/$postId');
  }

  void _sharePost(String postId) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      // Track share interaction for rewards
      _rewardsHandler.trackSocialInteraction(
        userId: currentUser.id,
        interactionType: 'share',
        targetUserId: _posts.firstWhere((p) => p.id == postId).authorId,
        metadata: {'postId': postId},
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openProfile(String userId) {
    // Navigate to user's social profile
    context.go('/social-profile/$userId');
  }

  void _navigateToCreatePost() {
    // Navigate to create post screen
    context.push('/social-create-post');
  }

  // Search-related methods & computed getters removed

  @override
  Widget build(BuildContext context) {
    return TwoSectionLayout(
      category: 'social',
      topPadding: EdgeInsets.zero,
      bottomPadding: EdgeInsets.zero,
      topSection: _buildTopSection(),
      bottomSection: _buildFeed(),
    );
  }

  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Home icon
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home icon button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.home_rounded, size: 28),
                  onPressed: () => context.go('/home'),
                ),
              ),
            ],
          ),
        ),
        // What's on your mind input
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ThoughtsInput(onTap: _navigateToCreatePost),
        ),
      ],
    );
  }

  Widget _buildFeed() {
    if (_isLoading && _posts.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _posts.map((post) {
        return PostCard(
          post: post,
          onLike: () => _likePost(post.id),
          onComment: () => _openComments(post.id),
          onShare: () => _sharePost(post.id),
          onProfileTap: () => _openProfile(post.authorId),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 64, color: context.colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow friends and join the conversation!',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreatePost,
            icon: const Icon(Icons.add),
            label: const Text('Create your first post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
