import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../widgets/custom_button.dart';
import '../../providers/social_providers.dart';
import '../../controllers/posts_controller.dart';
import '../../widgets/create_post/media_picker_widget.dart';
import '../../widgets/create_post/sport_tag_selector.dart';
import '../../widgets/create_post/visibility_selector.dart';
import '../../widgets/create_post/location_selector.dart';
import '../../widgets/create_post/mention_suggestions.dart';
import '../../widgets/create_post/post_preview_widget.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String? draftId;
  final String? initialContent;

  const CreatePostScreen({
    super.key,
    this.draftId,
    this.initialContent,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  bool _hasUnsavedChanges = false;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _textController.addListener(_onTextChanged);
    _textFocus.addListener(_onFocusChanged);
    
    // Initialize with draft or initial content
    if (widget.draftId != null) {
      _loadDraft();
    } else if (widget.initialContent != null) {
      _textController.text = widget.initialContent!;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocus.dispose();
    _scrollController.dispose();
    
    // Save draft on dispose
    if (_hasUnsavedChanges) {
      _saveDraft();
    }
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _hasUnsavedChanges) {
      _saveDraft();
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
    
    // Check for mentions and trigger suggestions
    final text = _textController.text;
    final selection = _textController.selection;
    
    if (selection.baseOffset > 0) {
      final beforeCursor = text.substring(0, selection.baseOffset);
      final words = beforeCursor.split(' ');
      final lastWord = words.isNotEmpty ? words.last : '';
      
      if (lastWord.startsWith('@') && lastWord.length > 1) {
        final query = lastWord.substring(1);
        ref.read(postsControllerProvider.notifier).searchMentions(query);
      }
    }
  }

  void _onFocusChanged() {
    if (!_textFocus.hasFocus) {
      ref.read(postsControllerProvider.notifier).clearMentionSuggestions();
    }
  }

  void _loadDraft() {
    final draft = ref.read(postsControllerProvider.notifier).getDraft(widget.draftId!);
    if (draft != null) {
      _textController.text = draft.content;
      // Load other draft properties...
    }
  }

  void _saveDraft() {
    if (_textController.text.trim().isNotEmpty) {
      ref.read(postsControllerProvider.notifier).saveDraftWithContent(
        draftId: widget.draftId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: _textController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsState = ref.watch(postsControllerProvider);

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showDiscardDialog() ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(context, theme, postsState),
        body: _isPreviewMode 
          ? _buildPreviewMode(context, theme, postsState)
          : _buildCreateMode(context, theme, postsState),
        bottomNavigationBar: _buildBottomBar(context, theme, postsState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, 
    ThemeData theme, 
    PostsState postsState,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () async {
          if (_hasUnsavedChanges) {
            final shouldDiscard = await _showDiscardDialog();
            if (shouldDiscard == true) {
              Navigator.pop(context);
            }
          } else {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.close),
      ),
      title: Text(_isPreviewMode ? 'Preview Post' : 'Create Post'),
      actions: [
        if (_isPreviewMode)
          TextButton(
            onPressed: () => setState(() => _isPreviewMode = false),
            child: const Text('Edit'),
          )
        else
          TextButton(
            onPressed: _canPreview() ? () => setState(() => _isPreviewMode = true) : null,
            child: const Text('Preview'),
          ),
        
        if (postsState.isDraftAutoSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildCreateMode(
    BuildContext context, 
    ThemeData theme, 
    PostsState postsState,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Text input
                _buildTextInput(theme),
                const SizedBox(height: 16),
                
                // Media section
                MediaPickerWidget(
                  selectedMedia: postsState.selectedMedia,
                  onMediaSelected: (media) {
                    ref.read(postsControllerProvider.notifier).addMedia(media);
                  },
                  onMediaRemoved: (index) {
                    ref.read(postsControllerProvider.notifier).removeMedia(index);
                  },
                  uploadProgress: postsState.uploadProgress,
                ),
                
                const SizedBox(height: 16),
                
                // Sport/Game tag
                SportTagSelector(
                  selectedSports: postsState.selectedSports,
                  onSportsChanged: (sports) {
                    ref.read(postsControllerProvider.notifier).updateSports(sports);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Location
                LocationSelector(
                  selectedLocation: postsState.selectedLocation,
                  onLocationChanged: (location) {
                    ref.read(postsControllerProvider.notifier).updateLocation(location);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Visibility settings
                VisibilitySelector(
                  visibility: postsState.visibility,
                  onVisibilityChanged: (visibility) {
                    ref.read(postsControllerProvider.notifier).updateVisibility(visibility);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Schedule post option
                _buildScheduleSection(theme, postsState),
              ],
            ),
          ),
        ),
        
        // Mention suggestions overlay
        if (postsState.mentionSuggestions.isNotEmpty && _textFocus.hasFocus)
          MentionSuggestions(
            suggestions: postsState.mentionSuggestions,
            onMentionSelected: (user) {
              _insertMention(user);
            },
          ),
      ],
    );
  }

  Widget _buildPreviewMode(
    BuildContext context, 
    ThemeData theme, 
    PostsState postsState,
  ) {
    return PostPreviewWidget(
      content: _textController.text,
      selectedMedia: postsState.selectedMedia,
      selectedSports: postsState.selectedSports,
      selectedLocation: postsState.selectedLocation,
      visibility: postsState.visibility,
      scheduledTime: postsState.scheduledTime,
    );
  }

  Widget _buildTextInput(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      child: TextField(
        controller: _textController,
        focusNode: _textFocus,
        maxLines: null,
        maxLength: 2000,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          counterStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSection(ThemeData theme, PostsState postsState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Schedule Post',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: postsState.scheduledTime != null,
                  onChanged: (value) {
                    if (value) {
                      _showSchedulePicker();
                    } else {
                      ref.read(postsControllerProvider.notifier).clearSchedule();
                    }
                  },
                ),
              ],
            ),
            
            if (postsState.scheduledTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 28), // Align with icon
                    Text(
                      'Scheduled for ${_formatScheduledTime(postsState.scheduledTime!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _showSchedulePicker,
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context, 
    ThemeData theme, 
    PostsState postsState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Draft indicator
          // Drafts indicator removed: drafts not available in PostsState
          
          const Spacer(),
          
          // Post button
          CustomButton(
            text: 'Post',
            onPressed: _canPost() ? _handlePost : null,
            loading: postsState.isCreatingPost,
          ),
        ],
      ),
    );
  }

  bool _canPreview() {
    return _textController.text.trim().isNotEmpty;
  }

  bool _canPost() {
    final postsState = ref.read(postsControllerProvider);
    return _textController.text.trim().isNotEmpty && 
           !postsState.isPosting &&
           !postsState.isUploadingMedia;
  }

  void _handlePost() async {
    final success = await ref.read(postsControllerProvider.notifier).createPostSimple(
      content: _textController.text,
    );
    
    if (success && mounted) {
      // Clear draft if exists
      if (widget.draftId != null) {
        ref.read(postsControllerProvider.notifier).deleteDraft(widget.draftId!);
      }
      
      Navigator.pop(context, true); // Return true to indicate post was created
    }
  }

  void _insertMention(dynamic user) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    if (selection.baseOffset > 0) {
      final beforeCursor = text.substring(0, selection.baseOffset);
      final afterCursor = text.substring(selection.baseOffset);
      
      // Find the @ symbol position
      final atIndex = beforeCursor.lastIndexOf('@');
      if (atIndex != -1) {
        final beforeAt = text.substring(0, atIndex);
        final mention = '@${user.username} ';
        final newText = beforeAt + mention + afterCursor;
        
        _textController.text = newText;
        _textController.selection = TextSelection.collapsed(
          offset: beforeAt.length + mention.length,
        );
        
        ref.read(postsControllerProvider.notifier).clearMentionSuggestions();
      }
    }
  }

  void _showSchedulePicker() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    
    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate.add(const Duration(hours: 1))),
      );
      
      if (selectedTime != null && mounted) {
        final scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        
        if (scheduledDateTime.isAfter(DateTime.now())) {
          ref.read(postsControllerProvider.notifier).schedulePostSimple(scheduledDateTime);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a future date and time'),
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Do you want to save as draft or discard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              _saveDraft();
              Navigator.pop(context, true);
            },
            child: const Text('Save Draft'),
          ),
        ],
      ),
    );
  }

  String _formatScheduledTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}

/// Drafts list bottom sheet
class DraftsList extends ConsumerWidget {
  final Function(String) onDraftSelected;

  const DraftsList({
    super.key,
    required this.onDraftSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final drafts = ref.watch(postsControllerProvider).drafts;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Drafts',
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
          
          if (drafts.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No drafts saved'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final draft = drafts[index];
                  
                  return Card(
                    child: ListTile(
                      title: Text(
                        draft.content.length > 50
                          ? '${draft.content.substring(0, 50)}...'
                          : draft.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Saved ${_formatDraftTime(draft.updatedAt)}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Text('Delete'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            onDraftSelected(draft.id);
                          } else if (value == 'delete') {
                            ref.read(postsControllerProvider.notifier)
                              .deleteDraft(draft.id);
                          }
                        },
                      ),
                      onTap: () => onDraftSelected(draft.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDraftTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
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
