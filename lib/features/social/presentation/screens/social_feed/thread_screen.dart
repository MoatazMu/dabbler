import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/core/widgets/loading_widget.dart';
import 'package:dabbler/features/social/providers/social_providers.dart';
import 'package:dabbler/features/social/presentation/widgets/post/post_content_widget.dart';
import 'package:dabbler/features/social/presentation/widgets/post/post_author_widget.dart';
import 'package:dabbler/features/social/presentation/widgets/comments/comments_thread.dart';
import 'package:dabbler/features/home/presentation/widgets/inline_post_composer.dart';
import 'package:dabbler/features/social/presentation/widgets/social_feed/post_media_widget.dart';
import '../../../services/social_service.dart';
import 'package:dabbler/services/moderation_service.dart';
import 'package:dabbler/utils/constants/route_constants.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  final String postId;

  const ThreadScreen({super.key, required this.postId});

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load post details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(socialFeedControllerProvider.notifier)
          .loadPostDetails(widget.postId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final postAsync = ref.watch(postDetailsProvider(widget.postId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: postAsync.when(
          data: (post) => FutureBuilder<bool>(
            future: _checkPostTakedown(post.id),
            builder: (context, takedownSnapshot) {
              if (takedownSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingWidget());
              }

              final isTakedown = takedownSnapshot.data ?? false;
              if (isTakedown) {
                return _buildTakedownPlaceholder(context, theme);
              }

              return Column(
                children: [
                  Expanded(child: _buildThreadContent(context, theme, post)),
                  _buildCommentInput(context, theme),
                ],
              );
            },
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load thread',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.refresh(postDetailsProvider(widget.postId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreadContent(
    BuildContext context,
    ThemeData theme,
    dynamic post,
  ) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnPost = post.authorId == currentUserId;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with back button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    foregroundColor: colorScheme.onSurface,
                    minimumSize: const Size(48, 48),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostAuthorWidget(
                        author: _AuthorData(
                          name: post.authorName,
                          avatar: post.authorAvatar,
                          isVerified: false,
                        ),
                        createdAt: post.createdAt,
                        city: post.cityName,
                        isEdited: false,
                        onProfileTap: () => _navigateToProfile(post.authorId),
                      ),
                      const SizedBox(height: 4),
                      // Post type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPostTypeColor(colorScheme, post.kind),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPostTypeLabel(post.kind),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: _getPostTypeTextColor(
                              colorScheme,
                              post.kind,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurface,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 20),
                            const SizedBox(width: 12),
                            const Text('Edit'),
                          ],
                        ),
                        onTap: () => _editPost(post),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 20,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                        onTap: () => _deletePost(post.id),
                      ),
                    ],
                  )
                else
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurface,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'hide',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_off_rounded, size: 20),
                            const SizedBox(width: 12),
                            const Text('Hide Post'),
                          ],
                        ),
                        onTap: () => _hidePost(post.id),
                      ),
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 20,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Report',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                        onTap: () => _reportPostWithData(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Post content card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post content
                    PostContentWidget(
                      content: post.content,
                      media: post.mediaUrls,
                      sports: const [],
                      mentions: const [],
                      hashtags: const [],
                      onMediaTap: (mediaIndex) =>
                          _viewMedia(post.mediaUrls, mediaIndex),
                      onMentionTap: (userId) => _navigateToProfile(userId),
                      onHashtagTap: (hashtag) => _searchHashtag(hashtag),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Vibes and engagement in one row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Primary vibe pill
                Consumer(
                  builder: (context, ref, _) {
                    final vibesAsync = ref.watch(
                      postVibesProvider(widget.postId),
                    );
                    return vibesAsync.when(
                      data: (rows) {
                        if (rows.isEmpty) return const SizedBox.shrink();
                        // Find primary vibe
                        final primaryVibe = rows.firstWhere((r) {
                          final vibe = r['vibes'] as Map<String, dynamic>?;
                          if (vibe == null) return false;
                          final id = vibe['id']?.toString();
                          return post.primaryVibeId != null &&
                              id == post.primaryVibeId;
                        }, orElse: () => rows.first);
                        final vibe =
                            primaryVibe['vibes'] as Map<String, dynamic>?;
                        if (vibe == null) return const SizedBox.shrink();
                        final label =
                            vibe['label']?.toString() ??
                            vibe['key']?.toString() ??
                            'Vibe';
                        final emoji = vibe['emoji']?.toString() ?? '';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (emoji.isNotEmpty)
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              if (emoji.isNotEmpty) const SizedBox(width: 4),
                              Text(
                                label,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                const Spacer(),
                // Like count
                _buildActionButton(
                  context: context,
                  theme: theme,
                  emoji: post.isLiked ? '❤️' : '🩶',
                  label: post.likesCount.toString(),
                  onTap: () => _handleLike(post.id),
                ),
                const SizedBox(width: 16),
                // Comment count
                _buildActionButton(
                  context: context,
                  theme: theme,
                  emoji: '💬',
                  label: post.commentsCount.toString(),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Action buttons - Like and Comment only
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _handleLike(post.id),
                    icon: Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                    ),
                    label: Text(post.isLiked ? 'Liked' : 'Like'),
                    style: FilledButton.styleFrom(
                      backgroundColor: post.isLiked
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      foregroundColor: post.isLiked
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: null, // Comments section is always visible below
                    icon: const Icon(Icons.comment_rounded, size: 20),
                    label: const Text('Comment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Comments section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Replies',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final commentsCount = ref.watch(
                      postCommentsCountProvider(widget.postId),
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$commentsCount',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Comments list with nested replies
        Consumer(
          builder: (context, ref, child) {
            final commentsAsync = ref.watch(
              postCommentsProvider(widget.postId),
            );

            return commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.comment_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No replies yet',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to reply!',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CommentsThread(
                          comment: comments[index],
                          onReply:
                              null, // Reply functionality is handled by the composer
                          onLike: (commentId) => _likeComment(commentId),
                          onReport: (commentId) => _reportComment(commentId),
                          onDelete: (commentId) => _deleteComment(commentId),
                          postAuthorId: post.authorId,
                        ),
                      ),
                      childCount: comments.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: LoadingWidget()),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load replies',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Bottom padding for comment input
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ThemeData theme,
    required String emoji,
    required String label,
    VoidCallback? onTap,
  }) {
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

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

  String _getPostTypeLabel(String kind) {
    final kindLower = kind.toLowerCase();
    switch (kindLower) {
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

  Color _getPostTypeColor(ColorScheme colorScheme, String kind) {
    final kindLower = kind.toLowerCase();
    switch (kindLower) {
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

  Color _getPostTypeTextColor(ColorScheme colorScheme, String kind) {
    final kindLower = kind.toLowerCase();
    switch (kindLower) {
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

  Widget _buildCommentInput(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    // Prevent DOM errors by checking if widget is still mounted
    if (!mounted) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Comment composer
            InlinePostComposer(
              mode: ComposerMode.comment,
              parentPostId: widget.postId,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkUserStatus() async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId.isEmpty) {
        return true; // Allow if not logged in (will fail auth anyway)
      }

      final isFrozen = await moderationService.isUserFrozen(currentUserId);
      final isShadowbanned = await moderationService.isUserShadowbanned(
        currentUserId,
      );

      if (isFrozen || isShadowbanned) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFrozen
                    ? 'Your account has been frozen. Please contact support.'
                    : 'Your account has been restricted. Some actions are disabled.',
              ),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      // If check fails, allow action (fail-safe)
      return true;
    }
  }

  void _handleLike(String postId) async {
    final canProceed = await _checkUserStatus();
    if (!canProceed) return;
    try {
      final socialService = SocialService();
      await socialService.toggleLike(postId);

      // Refresh post details to get updated like count
      ref.invalidate(postDetailsProvider(postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to toggle like: $e')));
      }
    }
  }

  void _likeComment(String commentId) async {
    final canProceed = await _checkUserStatus();
    if (!canProceed) return;

    try {
      final socialService = SocialService();
      await socialService.toggleCommentLike(commentId);

      // Refresh comments to get updated like count and status
      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle comment like: $e')),
        );
      }
    }
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final socialService = SocialService();
                await socialService.deleteComment(commentId);

                // Refresh comments
                ref.invalidate(postCommentsProvider(widget.postId));
                ref.invalidate(postDetailsProvider(widget.postId));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reply deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete reply: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reportComment(String commentId) {
    // Show report dialog
    showDialog(
      context: context,
      builder: (context) =>
          ReportDialog(type: ReportType.comment, commentId: commentId),
    );
  }

  void _editPost(dynamic post) {
    Navigator.pushNamed(
      context,
      '/social/edit-post',
      arguments: {'post': post},
    );
  }

  void _deletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(socialFeedControllerProvider.notifier)
                  .deletePost(postId);

              if (success && mounted) {
                Navigator.pop(context); // Go back to feed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewMedia(List<dynamic> media, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenMediaViewer(media: media, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToProfile(String userId) {
    context.go('${RoutePaths.userProfile}/$userId');
  }

  void _searchHashtag(String hashtag) {
    Navigator.pushNamed(
      context,
      '/social/hashtag',
      arguments: {'hashtag': hashtag},
    );
  }

  void _hidePost(String postId) async {
    try {
      final svc = SocialService();
      await svc.hidePost(postId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post hidden')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to hide post: $e')));
      }
    }
  }

  void _reportPostWithData() {
    showDialog(
      context: context,
      builder: (context) =>
          ReportDialog(type: ReportType.post, postId: widget.postId),
    );
  }

  Future<bool> _checkPostTakedown(String postId) async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      return await moderationService.isContentTakedown(ModTarget.post, postId);
    } catch (e) {
      // If check fails, assume not takedown to avoid blocking content
      return false;
    }
  }

  Widget _buildTakedownPlaceholder(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Content Removed',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This content has been removed due to a violation of our community guidelines.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Report dialog
class ReportDialog extends ConsumerStatefulWidget {
  final ReportType type;
  final String? postId;
  final String? commentId;

  const ReportDialog({
    super.key,
    required this.type,
    this.postId,
    this.commentId,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reportReasons = [
    'Spam',
    'Harassment',
    'Inappropriate content',
    'False information',
    'Hate speech',
    'Violence',
    'Other',
  ];

  /// Map UI reason string to ReportReason enum
  ReportReason _mapReasonToEnum(String reason) {
    switch (reason.toLowerCase()) {
      case 'spam':
        return ReportReason.spam;
      case 'harassment':
        return ReportReason.harassment;
      case 'inappropriate content':
      case 'nudity':
        return ReportReason.nudity;
      case 'false information':
      case 'scam':
        return ReportReason.scam;
      case 'hate speech':
      case 'hate':
        return ReportReason.hate;
      case 'violence':
      case 'danger':
        return ReportReason.danger;
      case 'abuse':
        return ReportReason.abuse;
      case 'illegal':
        return ReportReason.illegal;
      case 'impersonation':
        return ReportReason.impersonation;
      default:
        return ReportReason.other;
    }
  }

  /// Map ReportType to ModTarget
  ModTarget _getModTarget() {
    switch (widget.type) {
      case ReportType.post:
        return ModTarget.post;
      case ReportType.comment:
        return ModTarget.comment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.type.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why are you reporting this ${widget.type.name}?'),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reportReasons.map((reason) {
              final isSelected = _selectedReason == reason;

              return ChoiceChip(
                label: Text(reason),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedReason = selected ? reason : null);
                },
              );
            }).toList(),
          ),

          if (_selectedReason != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (_selectedReason != null && !_isSubmitting)
              ? _submitReport
              : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Report'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    final reason = _selectedReason;
    if (reason == null) return;

    // Determine target ID based on type
    final targetId = widget.type == ReportType.post
        ? widget.postId
        : widget.commentId;

    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit report: missing target ID'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final moderationService = ref.read(moderationServiceProvider);
      final details = _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim();

      await moderationService.submitReport(
        target: _getModTarget(),
        targetId: targetId,
        reason: _mapReasonToEnum(reason),
        details: details,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

enum ReportType { post, comment }

/// Simple author data class for passing to PostAuthorWidget
class _AuthorData {
  final String name;
  final String? avatar;
  final bool isVerified;

  _AuthorData({required this.name, this.avatar, this.isVerified = false});
}
