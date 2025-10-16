import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/social_providers.dart';

class CreatePostWidget extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool showQuickActions;
  final EdgeInsets? margin;

  const CreatePostWidget({
    super.key,
    this.onTap,
    this.showQuickActions = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Main create post row
              Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: currentUser.avatarUrl != null 
                      ? NetworkImage(currentUser.avatarUrl!)
                      : null,
                    child: currentUser.avatarUrl == null 
                      ? Text(
                          currentUser.displayName[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Expandable text field
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap ?? () => _openFullComposer(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'What\'s on your mind, ${currentUser.firstName ?? 'there'}?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (showQuickActions) ...[
                const SizedBox(height: 16),
                
                // Quick action buttons
                Row(
                  children: [
                    _buildQuickAction(
                      context: context,
                      icon: Icons.photo_library,
                      label: 'Photo',
                      color: Colors.green,
                      onTap: () => _openPhotoSelector(context),
                    ),
                    
                    _buildQuickAction(
                      context: context,
                      icon: Icons.videocam,
                      label: 'Video',
                      color: Colors.red,
                      onTap: () => _openVideoSelector(context),
                    ),
                    
                    _buildQuickAction(
                      context: context,
                      icon: Icons.sports_esports,
                      label: 'Game',
                      color: Colors.purple,
                      onTap: () => _shareGameResult(context),
                    ),
                    
                    _buildQuickAction(
                      context: context,
                      icon: Icons.location_on,
                      label: 'Location',
                      color: Colors.blue,
                      onTap: () => _addLocation(context),
                    ),
                  ],
                ),
              ],
              
              // Recent media preview
              _buildRecentMediaPreview(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMediaPreview(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final recentMedia = ref.watch(recentMediaProvider);
        
        return recentMedia.when(
          data: (mediaList) {
            if (mediaList.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Column(
              children: [
                const SizedBox(height: 12),
                
                // Divider
                Container(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                
                const SizedBox(height: 12),
                
                // Recent media header
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Recent',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Media grid
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mediaList.length.clamp(0, 10),
                    itemBuilder: (context, index) {
                      final media = mediaList[index];
                      
                      return GestureDetector(
                        onTap: () => _selectRecentMedia(context, media),
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Media thumbnail
                                if (media.type == 'image')
                                  Image.network(
                                    media.thumbnailUrl ?? media.url,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                            : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.image_not_supported);
                                    },
                                  )
                                else if (media.type == 'video')
                                  Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (media.thumbnailUrl != null)
                                        Image.network(
                                          media.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Center(
                                    child: Icon(
                                      _getFileIcon(media.type),
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 24,
                                    ),
                                  ),
                                
                                // Selection overlay
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'audio':
      case 'mp3':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openFullComposer(BuildContext context) {
    Navigator.pushNamed(context, '/post/create');
  }

  void _openPhotoSelector(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/post/create',
      arguments: {'mode': 'photo'},
    );
  }

  void _openVideoSelector(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/post/create',
      arguments: {'mode': 'video'},
    );
  }

  void _shareGameResult(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/post/create',
      arguments: {'mode': 'game'},
    );
  }

  void _addLocation(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/post/create',
      arguments: {'mode': 'location'},
    );
  }

  void _selectRecentMedia(BuildContext context, dynamic media) {
    Navigator.pushNamed(
      context,
      '/post/create',
      arguments: {
        'selectedMedia': [media],
      },
    );
  }
}

/// Expandable create post widget for profile screens
class ProfileCreatePostWidget extends ConsumerWidget {
  final VoidCallback? onTap;

  const ProfileCreatePostWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap ?? () => Navigator.pushNamed(context, '/post/create'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: currentUser.avatarUrl != null 
                    ? NetworkImage(currentUser.avatarUrl!)
                    : null,
                  child: currentUser.avatarUrl == null 
                    ? Text(
                        currentUser.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Text(
                    'Share something with your followers...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                
                Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating create post button
class FloatingCreatePostButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isVisible;

  const FloatingCreatePostButton({
    super.key,
    this.onTap,
    this.isVisible = true,
  });

  @override
  State<FloatingCreatePostButton> createState() => _FloatingCreatePostButtonState();
}

class _FloatingCreatePostButtonState extends State<FloatingCreatePostButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FloatingCreatePostButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value * 0.5,
            child: FloatingActionButton.extended(
              onPressed: widget.onTap ?? () => Navigator.pushNamed(context, '/post/create'),
              icon: const Icon(Icons.add),
              label: const Text('Post'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }
}

/// Create post story widget
class CreatePostStoryWidget extends ConsumerWidget {
  final VoidCallback? onTap;

  const CreatePostStoryWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, '/story/create'),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.3),
              theme.colorScheme.primary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: currentUser.avatarUrl != null 
                  ? NetworkImage(currentUser.avatarUrl!)
                  : null,
                child: currentUser.avatarUrl == null 
                  ? Text(
                      currentUser.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
              ),
            ),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Create Story',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Post draft indicator widget
class PostDraftIndicator extends ConsumerWidget {
  const PostDraftIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsCount = ref.watch(savedDraftsCountProvider);
    
    return draftsCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.drafts),
              title: Text('$count saved draft${count == 1 ? '' : 's'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/post/drafts'),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
