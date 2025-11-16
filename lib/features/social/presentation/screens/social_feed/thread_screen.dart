import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/core/widgets/loading_widget.dart';
import 'package:dabbler/features/social/providers/social_providers.dart';
import 'package:dabbler/features/social/presentation/widgets/post/post_content_widget.dart';
import 'package:dabbler/features/social/presentation/widgets/post/post_author_widget.dart';
import 'package:dabbler/features/social/presentation/widgets/comments/comments_thread.dart';
import 'package:dabbler/features/social/presentation/widgets/comments/comment_input.dart';
import '../../../services/social_service.dart';
import 'package:dabbler/utils/constants/route_constants.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  final String postId;

  const ThreadScreen({super.key, required this.postId});

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  String? _replyingToCommentId;

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
    _commentController.dispose();
    _commentFocus.dispose();
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
          data: (post) => Column(
            children: [
              Expanded(child: _buildThreadContent(context, theme, post)),
              _buildCommentInput(context, theme),
            ],
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
                const Spacer(),
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
                    // Author info
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

                    const SizedBox(height: 16),
                    // Vibes display (primary + assigned)
                    Consumer(
                      builder: (context, ref, _) {
                        final vibesAsync = ref.watch(
                          postVibesProvider(widget.postId),
                        );
                        return vibesAsync.when(
                          data: (rows) {
                            if (rows.isEmpty && post.primaryVibeId == null) {
                              return const SizedBox.shrink();
                            }
                            // Build chips; prefer assigned vibes data for label/emoji
                            final chips = <Widget>[];
                            for (final r in rows) {
                              final vibe = r['vibes'] as Map<String, dynamic>?;
                              if (vibe == null) continue;
                              final id = vibe['id']?.toString();
                              final label =
                                  vibe['label']?.toString() ??
                                  vibe['key']?.toString() ??
                                  'Vibe';
                              final emoji = vibe['emoji']?.toString() ?? '';
                              final isPrimary =
                                  (post.primaryVibeId != null &&
                                  id == post.primaryVibeId);
                              chips.add(
                                Chip(
                                  label: Text(
                                    '${emoji.isNotEmpty ? '$emoji ' : ''}$label',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  labelStyle: theme.textTheme.bodySmall,
                                  backgroundColor: isPrimary
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  side: BorderSide(
                                    color: isPrimary
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant
                                              .withOpacity(0.4),
                                  ),
                                ),
                              );
                            }
                            return chips.isEmpty
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: chips,
                                    ),
                                  );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),

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

                    const SizedBox(height: 20),

                    // Engagement stats - minimal one line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          theme,
                          icon: Icons.favorite_rounded,
                          count: post.likesCount,
                          onTap: () => _handleLike(post.id),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          theme,
                          icon: Icons.comment_rounded,
                          count: post.commentsCount,
                          onTap: () => _focusCommentInput(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action buttons - Like and Comment only
                    Row(
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
                            onPressed: () => _focusCommentInput(),
                            icon: const Icon(Icons.comment_rounded, size: 20),
                            label: const Text('Comment'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
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
                  ],
                ),
              ),
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
                          onReply: (commentId) => _replyToComment(commentId),
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

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
            // Reply indicator
            if (_replyingToCommentId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Replying to comment',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _replyingToCommentId = null),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Comment input
            CommentInput(
              controller: _commentController,
              focusNode: _commentFocus,
              hintText: _replyingToCommentId != null
                  ? 'Write a reply...'
                  : 'Add a reply...',
              onSubmit: (content) => _submitComment(content),
              onChanged: (text) {
                // Handle mention suggestions
                _handleCommentTextChanged(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLike(String postId) async {
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

  void _focusCommentInput() {
    _commentFocus.requestFocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _replyToComment(String commentId) {
    setState(() => _replyingToCommentId = commentId);
    _focusCommentInput();
  }

  void _submitComment(String content) async {
    if (content.trim().isNotEmpty) {
      final success = await ref
          .read(socialFeedControllerProvider.notifier)
          .addComment(
            postId: widget.postId,
            content: content,
            parentCommentId: _replyingToCommentId,
          );

      if (success) {
        _commentController.clear();
        setState(() => _replyingToCommentId = null);

        // Refresh comments to show the new comment
        ref.invalidate(postCommentsProvider(widget.postId));
        ref.invalidate(postDetailsProvider(widget.postId));

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reply added')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to add reply')));
        }
      }
    }
  }

  void _handleCommentTextChanged(String text) {
    // Handle @mentions in comments
    final selection = _commentController.selection;
    if (selection.baseOffset > 0) {
      final beforeCursor = text.substring(0, selection.baseOffset);
      final words = beforeCursor.split(' ');
      final lastWord = words.isNotEmpty ? words.last : '';

      if (lastWord.startsWith('@') && lastWord.length > 1) {
        // Trigger mention suggestions for query: ${lastWord.substring(1)}
      }
    }
  }

  void _likeComment(String commentId) {
    // Implement comment like
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
    Navigator.pushNamed(
      context,
      '/media-viewer',
      arguments: {'media': media, 'initialIndex': initialIndex},
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
}

/// Report dialog
class ReportDialog extends StatefulWidget {
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
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _reportReasons = [
    'Spam',
    'Harassment',
    'Inappropriate content',
    'False information',
    'Hate speech',
    'Violence',
    'Other',
  ];

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
          onPressed: _selectedReason != null ? _submitReport : null,
          child: const Text('Report'),
        ),
      ],
    );
  }

  void _submitReport() {
    final reason = _selectedReason;
    if (reason == null) return;
    final details = _detailsController.text.trim().isEmpty
        ? null
        : _detailsController.text.trim();
    final svc = SocialService();
    if (widget.type == ReportType.post && widget.postId != null) {
      svc
          .reportPost(postId: widget.postId!, reason: reason, details: details)
          .then((_) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report submitted successfully')),
            );
          })
          .catchError((e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit report: $e')),
            );
          });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report submitted')));
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
