import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dabbler/utils/enums/social_enums.dart';
import 'package:dabbler/data/social/social_repository.dart';
import 'package:dabbler/features/home/presentation/providers/home_providers.dart';
import 'package:dabbler/features/social/providers/social_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dabbler/core/design_system/design_system.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(),
);

enum ComposerMode { post, comment }

class InlinePostComposer extends ConsumerStatefulWidget {
  const InlinePostComposer({
    super.key,
    this.mode = ComposerMode.post,
    this.parentPostId,
  });

  final ComposerMode mode;
  final String? parentPostId;

  @override
  ConsumerState<InlinePostComposer> createState() => _InlinePostComposerState();
}

class _InlinePostComposerState extends ConsumerState<InlinePostComposer> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isPosting = false;
  String _selectedKind = 'moment'; // 'moment', 'dab', 'kickin'
  dynamic _selectedVibeId;
  List<Map<String, dynamic>> _availableVibes = [];
  bool _isLoadingVibes = false;
  final List<XFile> _selectedMedia = [];

  @override
  void initState() {
    super.initState();
    _loadVibes();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVibes() async {
    setState(() => _isLoadingVibes = true);
    try {
      final repo = ref.read(socialRepositoryProvider);
      final vibes = await repo.getVibesForKind(_selectedKind);
      if (mounted) {
        setState(() {
          // Reorder so Neutral (if present) is first in the list.
          final neutralVibes = vibes
              .where((v) => (v['key'] as String?)?.toLowerCase() == 'neutral')
              .toList();
          final otherVibes = vibes
              .where((v) => (v['key'] as String?)?.toLowerCase() != 'neutral')
              .toList();
          _availableVibes = [...neutralVibes, ...otherVibes];

          // Ensure we always have a default vibe selected.
          if (_availableVibes.isNotEmpty) {
            final neutral = _availableVibes.firstWhere(
              (v) => (v['key'] as String?)?.toLowerCase() == 'neutral',
              orElse: () => _availableVibes.first,
            );
            _selectedVibeId = neutral['id'] ?? _availableVibes.first['id'];
          }
          _isLoadingVibes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVibes = false);
      }
    }
  }

  void _onKindChanged(String kind) {
    if (_selectedKind == kind) return;
    setState(() {
      _selectedKind = kind;
    });
    _loadVibes();
  }

  Future<void> _handlePost() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Extra safety: do not allow posting without a vibe.
    if (_selectedVibeId == null && _availableVibes.isNotEmpty) {
      final neutral = _availableVibes.firstWhere(
        (v) => (v['key'] as String?)?.toLowerCase() == 'neutral',
        orElse: () => _availableVibes.first,
      );
      setState(() {
        _selectedVibeId = neutral['id'] ?? _availableVibes.first['id'];
      });
    }

    if (_selectedVibeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a vibe before posting.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final repo = ref.read(socialRepositoryProvider);

      Map<String, dynamic>? mediaJson;
      if (_selectedMedia.isNotEmpty) {
        // For now support a single image per post.
        final file = _selectedMedia.first;
        mediaJson = await repo.uploadPostMedia(file);
      }

      if (widget.mode == ComposerMode.post) {
        await repo.createPost(
          kind: _selectedKind,
          visibility: PostVisibility.public,
          body: text,
          primaryVibeId: _selectedVibeId,
          media: mediaJson,
          // TODO: Add location, game support
        );

        // Refresh the main feed when creating a post
        ref.invalidate(latestFeedPostsProvider);
      } else {
        if (widget.parentPostId == null) {
          throw Exception('parentPostId is required for comments');
        }

        await repo.createComment(
          postId: widget.parentPostId!,
          body: text,
          media: mediaJson,
        );

        // Refresh thread comments after posting
        ref.invalidate(postCommentsProvider(widget.parentPostId!));
        ref.invalidate(postDetailsProvider(widget.parentPostId!));
      }

      if (mounted) {
        _textController.clear();
        _focusNode.unfocus();
        setState(() {
          _isPosting = false;
          _selectedKind = 'moment'; // Reset to default
          _selectedMedia.clear();
        });

        // Close the modal if in post mode
        if (widget.mode == ComposerMode.post) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildAttachmentOption(
                icon: Iconsax.camera_copy,
                label: 'Camera',
                onTap: () async {
                  Navigator.pop(context);
                  final photo = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    setState(() => _selectedMedia.add(photo));
                  }
                },
              ),
              _buildAttachmentOption(
                icon: Iconsax.gallery_copy,
                label: 'Gallery',
                onTap: () async {
                  Navigator.pop(context);
                  final images = await _imagePicker.pickMultiImage();
                  if (images.isNotEmpty) {
                    setState(() => _selectedMedia.addAll(images));
                  }
                },
              ),
              _buildAttachmentOption(
                icon: Iconsax.document_copy,
                label: 'Files',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement file picker
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostTypeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'Choose your post type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildPostTypeOption(
                icon: Iconsax.gallery_copy,
                label: 'Moment',
                subtitle: 'Share a photo or video moment',
                value: 'moment',
              ),
              _buildPostTypeOption(
                icon: Iconsax.message_text_copy,
                label: 'Dab',
                subtitle: 'Quick thoughts and updates',
                value: 'dab',
              ),
              _buildPostTypeOption(
                icon: Iconsax.medal_star_copy,
                label: 'Kick-in',
                subtitle: 'Game-related content',
                value: 'kickin',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVibeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose a vibe',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Vibes list
              Expanded(
                child: _isLoadingVibes
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 24,
                        ),
                        itemCount: _availableVibes.length,
                        itemBuilder: (context, index) {
                          final vibe = _availableVibes[index];
                          final id = vibe['id'];
                          final label = vibe['label_en'] ?? vibe['key'];
                          final emoji = vibe['emoji'] ?? '';
                          final isSelected = _selectedVibeId == id;

                          return _buildVibeOption(
                            emoji: emoji,
                            label: label,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedVibeId = id;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibeOption({
    required String emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Iconsax.tick_circle_copy, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedKind == value;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _onKindChanged(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Iconsax.tick_circle_copy, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.colorTokens;
    final hasContent =
        _textController.text.isNotEmpty || _selectedMedia.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: tokens.header,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First line: typing space
                AppTextArea(
                  controller: _textController,
                  placeholder: "What's on your mind?",
                  minLines: 1,
                  maxLines: 5,
                ),

                const SizedBox(height: 12),

                // Second line: controls
                Row(
                  children: [
                    // Attachment button
                    GestureDetector(
                      onTap: _showAttachmentOptions,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/add.svg',
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            colorScheme.onSurfaceVariant,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Vibe pill (always visible, tap to change)
                    InkWell(
                      onTap: _showVibeOptions,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Builder(
                          builder: (context) {
                            final fallback = _availableVibes.isNotEmpty
                                ? _availableVibes.first
                                : null;
                            final selected = _availableVibes.firstWhere(
                              (v) => v['id'] == _selectedVibeId,
                              orElse: () =>
                                  fallback ??
                                  {'emoji': '😊', 'label_en': 'Neutral'},
                            );
                            final emoji = (selected['emoji'] ?? '😊')
                                .toString();
                            final label =
                                (selected['label_en'] ??
                                        selected['key'] ??
                                        'Neutral')
                                    .toString();

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Post type pill (clickable)
                    InkWell(
                      onTap: _showPostTypeOptions,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedKind == 'moment'
                              ? 'Moments'
                              : _selectedKind == 'dab'
                              ? 'Dab'
                              : 'Kick-in',
                          style: AppTypography.labelMedium.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Send/Post button
                    if (hasContent)
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 60,
                          maxWidth: 100,
                          minHeight: 36,
                          maxHeight: 36,
                        ),
                        child: AppButton(
                          onPressed: _isPosting ? null : _handlePost,
                          label: _isPosting ? 'Posting...' : 'Post',
                          type: AppButtonType.filled,
                          size: AppButtonSize.sm,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Media preview
          if (_selectedMedia.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Iconsax.gallery_copy),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMedia.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.close_circle_copy,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
