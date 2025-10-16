import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as core;
import '../../providers/social_providers.dart';
import '../../../../../utils/enums/social_enums.dart';
import '../../widgets/post/post_content_widget.dart';
import '../../widgets/post/post_actions_widget.dart';
import '../../widgets/post/post_author_widget.dart';
import '../../widgets/post/share_post_bottom_sheet.dart';
import '../../widgets/comments/comments_thread.dart';
import '../../widgets/comments/comment_input.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    
    // Load post details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialFeedControllerProvider.notifier).loadPostDetails(widget.postId);
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
    final postAsync = ref.watch(postDetailsProvider(widget.postId));
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: postAsync.when(
        data: (post) => _buildPostContent(context, theme, post),
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: core.ErrorWidget(
            message: error.toString(),
            onRetry: () => ref.refresh(postDetailsProvider(widget.postId)),
          ),
        ),
      ),
      bottomNavigationBar: _buildCommentInput(context, theme),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('Post'),
      actions: [
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'copy_link',
              child: ListTile(
                leading: Icon(Icons.link),
                title: Text('Copy Link'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.flag),
                title: Text('Report'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) => _handleMenuAction(value.toString()),
        ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context, ThemeData theme, dynamic post) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnPost = post.authorId == currentUserId;
    
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Post content
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info
                      PostAuthorWidget(
                        author: post.author,
                        createdAt: post.createdAt,
                        location: post.location,
                        isEdited: post.isEdited,
                        onProfileTap: () => _navigateToProfile(post.authorId),
                        actions: isOwnPost ? [
                          PostAction(
                            icon: Icons.edit,
                            label: 'Edit',
                            onTap: () => _editPost(post),
                          ),
                          PostAction(
                            icon: Icons.delete,
                            label: 'Delete',
                            onTap: () => _deletePost(post.id),
                            isDestructive: true,
                          ),
                        ] : [
                          PostAction(
                            icon: Icons.person_off,
                            label: 'Block User',
                            onTap: () => _blockUser(post.authorId),
                            isDestructive: true,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Post content
                      PostContentWidget(
                        content: post.content,
                        media: post.media,
                        sports: post.sports,
                        mentions: post.mentions,
                        hashtags: post.hashtags,
                        onMediaTap: (mediaIndex) => _viewMedia(post.media, mediaIndex),
                        onMentionTap: (userId) => _navigateToProfile(userId),
                        onHashtagTap: (hashtag) => _searchHashtag(hashtag),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Post actions
                      PostActionsWidget(
                        post: post,
                        onLike: () => _handleLike(post.id),
                        onComment: () => _focusCommentInput(),
                        onShare: () => _sharePost(post),
                        onReaction: (reaction) => _handleReaction(post.id, reaction),
                      ),
                      
                      // Engagement stats
                      _buildEngagementStats(theme, post),
                    ],
                  ),
                ),
              ),
              
              // Comments header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Consumer(
                        builder: (context, ref, child) {
                          final commentsCount = ref.watch(postCommentsCountProvider(widget.postId));
                          return Text(
                            '$commentsCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Comments thread
              Consumer(
                builder: (context, ref, child) {
                  final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
                  
                  return commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to comment!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => CommentsThread(
                            comment: comments[index],
                            onReply: (commentId) => _replyToComment(commentId),
                            onLike: (commentId) => _likeComment(commentId),
                            onReport: (commentId) => _reportComment(commentId),
                            onDelete: (commentId) => _deleteComment(commentId),
                            postAuthorId: post.authorId,
                          ),
                          childCount: comments.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: LoadingWidget()),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text('Error loading comments: $error'),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Bottom padding for comment input
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementStats(ThemeData theme, dynamic post) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildStatItem(
              theme,
              icon: Icons.favorite,
              count: post.likesCount,
              label: 'likes',
              onTap: () => _showLikesList(post.id),
            ),
            
            VerticalDivider(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 32,
            ),
            
            _buildStatItem(
              theme,
              icon: Icons.comment,
              count: post.commentsCount,
              label: 'comments',
              onTap: () => _focusCommentInput(),
            ),
            
            VerticalDivider(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 32,
            ),
            
            _buildStatItem(
              theme,
              icon: Icons.share,
              count: post.sharesCount,
              label: 'shares',
              onTap: () => _sharePost(post),
            ),
            
            const Spacer(),
            
            Text(
              _formatPostTime(post.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Replying to comment',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _replyingToCommentId = null),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_replyingToCommentId != null)
              const SizedBox(height: 8),
            
            // Comment input
            CommentInput(
              controller: _commentController,
              focusNode: _commentFocus,
              hintText: _replyingToCommentId != null 
                ? 'Write a reply...'
                : 'Add a comment...',
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _sharePost(null);
        break;
      case 'copy_link':
        _copyPostLink();
        break;
      case 'report':
        _reportPost();
        break;
    }
  }

  void _handleLike(String postId) {
    ref.read(socialFeedControllerProvider.notifier).reactToPost(postId, ReactionType.like.toString().split('.').last);
  }

  void _handleReaction(String postId, ReactionType reaction) {
    ref.read(socialFeedControllerProvider.notifier).reactToPost(postId, reaction.toString().split('.').last);
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

  void _submitComment(String content) {
    if (content.trim().isNotEmpty) {
      ref.read(socialFeedControllerProvider.notifier).addComment(
        postId: widget.postId,
        content: content,
        parentCommentId: _replyingToCommentId,
      );
      
      _commentController.clear();
      setState(() => _replyingToCommentId = null);
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
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete comment
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
      builder: (context) => const ReportDialog(
        type: ReportType.comment,
      ),
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
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(socialFeedControllerProvider.notifier)
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

  void _blockUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user? You won\'t see their posts anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block user
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _sharePost(dynamic post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SharePostBottomSheet(post: post),
    );
  }

  void _copyPostLink() {
    final link = 'https://dabbler.app/post/${widget.postId}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _reportPost() {
    showDialog(
      context: context,
      builder: (context) => const ReportDialog(
        type: ReportType.post,
      ),
    );
  }

  void _showLikesList(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LikesListSheet(postId: postId),
    );
  }

  void _viewMedia(List<dynamic> media, int initialIndex) {
    Navigator.pushNamed(
      context,
      '/media-viewer',
      arguments: {
        'media': media,
        'initialIndex': initialIndex,
      },
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userId': userId},
    );
  }

  void _searchHashtag(String hashtag) {
    Navigator.pushNamed(
      context,
      '/social/hashtag',
      arguments: {'hashtag': hashtag},
    );
  }

  String _formatPostTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Likes list bottom sheet
class LikesListSheet extends ConsumerWidget {
  final String postId;

  const LikesListSheet({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final likesAsync = ref.watch(postLikesProvider(postId));
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Likes',
                style: theme.textTheme.headlineSmall?.copyWith(
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
          
          Expanded(
            child: likesAsync.when(
              data: (likes) => ListView.builder(
                itemCount: likes.length,
                itemBuilder: (context, index) {
                  final like = likes[index];
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: like.avatarUrl != null && like.avatarUrl!.isNotEmpty
                        ? NetworkImage(like.avatarUrl!)
                        : null,
                      child: like.avatarUrl == null || like.avatarUrl!.isEmpty
                        ? Text(like.displayName[0].toUpperCase())
                        : null,
                    ),
                    title: Text(like.displayName),
                    subtitle: Text('@${like.email}'),
                    trailing: const Icon(Icons.favorite), // Default to like icon for now
                    onTap: () => _navigateToProfile(context, like.id),
                  );
                },
              ),
              loading: () => const Center(child: LoadingWidget()),
              error: (error, stack) => Center(
                child: Text('Error loading likes: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userId': userId},
    );
  }
}

/// Report dialog
class ReportDialog extends StatefulWidget {
  final ReportType type;

  const ReportDialog({
    super.key,
    required this.type,
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
    // Implement report submission
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted successfully')),
    );
  }
}

enum ReportType { post, comment }
