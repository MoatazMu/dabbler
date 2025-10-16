import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../../../core/models/user_model.dart';

/// Mention type for different kinds of mentions
enum MentionType {
  user,
  group,
  topic,
  hashtag,
}

/// Mention suggestion item
class MentionSuggestion {
  final String id;
  final String displayText;
  final String searchText;
  final String? avatarUrl;
  final MentionType type;
  final Map<String, dynamic>? metadata;

  const MentionSuggestion({
    required this.id,
    required this.displayText,
    required this.searchText,
    this.avatarUrl,
    required this.type,
    this.metadata,
  });

  factory MentionSuggestion.fromUser(UserModel user) {
    return MentionSuggestion(
      id: user.id,
      displayText: user.displayName,
      searchText: '${user.displayName} ${user.displayName}'.toLowerCase(),
      avatarUrl: user.profileImageUrl,
      type: MentionType.user,
      metadata: {
        'username': user.displayName,
        'isVerified': false,
      },
    );
  }
}

/// Extracted mention from text
class ExtractedMention {
  final String id;
  final String displayText;
  final MentionType type;
  final int startIndex;
  final int endIndex;

  const ExtractedMention({
    required this.id,
    required this.displayText,
    required this.type,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Permission check result
enum MentionPermission {
  allowed,
  blocked,
  restricted,
  notFound,
}

/// Text field with comprehensive @ mention support
class MentionInputField extends StatefulWidget {
  /// Text editing controller
  final TextEditingController? controller;
  
  /// Hint text
  final String? hintText;
  
  /// Maximum number of lines
  final int? maxLines;
  
  /// Minimum number of lines
  final int? minLines;
  
  /// Maximum character length
  final int? maxLength;
  
  /// Input decoration
  final InputDecoration? decoration;
  
  /// Text style
  final TextStyle? style;
  
  /// Mention text style
  final TextStyle? mentionStyle;
  
  /// Callback when text changes
  final ValueChanged<String>? onChanged;
  
  /// Callback when mentions are extracted
  final ValueChanged<List<ExtractedMention>>? onMentionsChanged;
  
  /// Callback to fetch mention suggestions
  final Future<List<MentionSuggestion>> Function(String query)? onSearchMentions;
  
  /// Callback to validate mention permissions
  final Future<MentionPermission> Function(String id, MentionType type)? onValidateMention;
  
  /// Callback when submit is pressed
  final ValueChanged<String>? onSubmitted;
  
  /// Enable undo/redo functionality
  final bool enableUndoRedo;
  
  /// Show mention avatars in suggestions
  final bool showAvatars;
  
  /// Maximum number of suggestions to show
  final int maxSuggestions;
  
  /// Enable haptic feedback
  final bool enableHaptics;
  
  /// Custom mention trigger character (default: @)
  final String mentionTrigger;
  
  /// Supported mention types
  final Set<MentionType> supportedTypes;
  
  /// Auto focus on widget creation
  final bool autofocus;
  
  /// Enable keyboard navigation
  final bool enableKeyboardNavigation;
  
  /// Custom suggestion item builder
  final Widget Function(MentionSuggestion suggestion, VoidCallback onTap)? suggestionBuilder;

  const MentionInputField({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.decoration,
    this.style,
    this.mentionStyle,
    this.onChanged,
    this.onMentionsChanged,
    this.onSearchMentions,
    this.onValidateMention,
    this.onSubmitted,
    this.enableUndoRedo = true,
    this.showAvatars = true,
    this.maxSuggestions = 5,
    this.enableHaptics = true,
    this.mentionTrigger = '@',
    this.supportedTypes = const {MentionType.user},
    this.autofocus = false,
    this.enableKeyboardNavigation = true,
    this.suggestionBuilder,
  });

  @override
  State<MentionInputField> createState() => _MentionInputFieldState();
}

class _MentionInputFieldState extends State<MentionInputField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  List<MentionSuggestion> _suggestions = [];
  List<ExtractedMention> _mentions = [];
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  int _selectedSuggestionIndex = -1;
  bool _showSuggestions = false;
  String _currentQuery = '';
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    if (widget.enableUndoRedo) {
      _undoStack.add(_controller.text);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        children: [
          _buildTextField(),
          if (_mentions.isNotEmpty) _buildMentionedUsersPreview(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      style: widget.style,
      decoration: widget.decoration ?? const InputDecoration(
        hintText: 'Type @ to mention someone...',
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
      onSubmitted: _onSubmitted,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onTap: () => _updateSuggestions(),
    );
  }

  Widget _buildMentionedUsersPreview() {
    if (_mentions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mentioned Users:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _mentions.map((mention) => _buildMentionChip(mention)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionChip(ExtractedMention mention) {
    return Chip(
      avatar: mention.type == MentionType.user
          ? CircleAvatar(
              radius: 12,
              child: Text(mention.displayText.substring(0, 1).toUpperCase()),
            )
          : Icon(_getTypeIcon(mention.type), size: 16),
      label: Text(
        mention.displayText,
        style: const TextStyle(fontSize: 12),
      ),
      onDeleted: () => _removeMention(mention),
      deleteIconColor: Colors.grey[600],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      width: MediaQuery.of(context).size.width - 32,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final isSelected = index == _selectedSuggestionIndex;
                
                return widget.suggestionBuilder?.call(
                  suggestion,
                  () => _selectSuggestion(suggestion),
                ) ?? _buildDefaultSuggestionItem(suggestion, isSelected);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultSuggestionItem(MentionSuggestion suggestion, bool isSelected) {
    return Container(
      color: isSelected ? Theme.of(context).focusColor : null,
      child: ListTile(
        dense: true,
        leading: widget.showAvatars ? _buildSuggestionAvatar(suggestion) : null,
        title: Text(
          suggestion.displayText,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: suggestion.type == MentionType.user && suggestion.metadata?['username'] != null
            ? Text('@${suggestion.metadata!['username']}')
            : null,
        trailing: suggestion.metadata?['isVerified'] == true
            ? Icon(Icons.verified, size: 16, color: Colors.blue[600])
            : null,
        onTap: () => _selectSuggestion(suggestion),
      ),
    );
  }

  Widget _buildSuggestionAvatar(MentionSuggestion suggestion) {
    if (suggestion.avatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(suggestion.avatarUrl!),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
      child: Icon(
        _getTypeIcon(suggestion.type),
        size: 16,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  IconData _getTypeIcon(MentionType type) {
    switch (type) {
      case MentionType.user:
        return Icons.person;
      case MentionType.group:
        return Icons.group;
      case MentionType.topic:
        return Icons.topic;
      case MentionType.hashtag:
        return Icons.tag;
    }
  }

  void _onTextChanged() {
    if (widget.enableUndoRedo) {
      _updateUndoStack();
    }
    
    _updateSuggestions();
    _extractMentions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
    } else {
      _hideSuggestions();
    }
  }

  void _updateSuggestions() async {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _hideSuggestions();
      return;
    }

    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    
    // Find the last @ symbol before cursor
    final lastAtIndex = textBeforeCursor.lastIndexOf(widget.mentionTrigger);
    
    if (lastAtIndex == -1) {
      _hideSuggestions();
      return;
    }

    // Check if there's a space between @ and cursor (invalid mention)
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
      _hideSuggestions();
      return;
    }

    _currentQuery = textAfterAt;
    _mentionStartIndex = lastAtIndex;

    if (_currentQuery.isNotEmpty) {
      _searchMentions(_currentQuery);
    } else {
      _hideSuggestions();
    }
  }

  void _searchMentions(String query) async {
    if (widget.onSearchMentions == null) return;

    try {
      final suggestions = await widget.onSearchMentions!(query);
      setState(() {
        _suggestions = suggestions.take(widget.maxSuggestions).toList();
        _selectedSuggestionIndex = _suggestions.isNotEmpty ? 0 : -1;
      });
      _displaySuggestions();
    } catch (e) {
      _hideSuggestions();
    }
  }

  void _displaySuggestions() {
    if (_suggestions.isEmpty || _showSuggestions) return;

    _showSuggestions = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildSuggestionsOverlay(),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    if (!_showSuggestions) return;
    
    _showSuggestions = false;
    _removeOverlay();
    _selectedSuggestionIndex = -1;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(MentionSuggestion suggestion) async {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }

    // Validate mention permission
    if (widget.onValidateMention != null) {
      final permission = await widget.onValidateMention!(suggestion.id, suggestion.type);
      if (permission != MentionPermission.allowed) {
        _showPermissionError(permission);
        return;
      }
    }

    final text = _controller.text;
    final mentionText = '${widget.mentionTrigger}${suggestion.displayText}';
    
    final newText = text.substring(0, _mentionStartIndex) +
        mentionText +
        text.substring(_controller.selection.baseOffset);
    
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: _mentionStartIndex + mentionText.length,
    );
    
    _hideSuggestions();
    _extractMentions();
  }

  void _extractMentions() {
    final text = _controller.text;
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    
    final newMentions = <ExtractedMention>[];
    
    for (final match in matches) {
      final mention = ExtractedMention(
        id: match.group(1)!,
        displayText: match.group(1)!,
        type: MentionType.user,
        startIndex: match.start,
        endIndex: match.end,
      );
      newMentions.add(mention);
    }
    
    if (!_listEquals(_mentions, newMentions)) {
      setState(() {
        _mentions = newMentions;
      });
      widget.onMentionsChanged?.call(_mentions);
    }
  }

  void _removeMention(ExtractedMention mention) {
    final text = _controller.text;
    final newText = text.substring(0, mention.startIndex) +
        text.substring(mention.endIndex);
    
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: mention.startIndex,
    );
    
    _extractMentions();
  }

  void _updateUndoStack() {
    final currentText = _controller.text;
    if (_undoStack.isEmpty || _undoStack.last != currentText) {
      _undoStack.add(currentText);
      _redoStack.clear();
      
      // Limit undo stack size
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0);
      }
    }
  }

  void _undo() {
    if (_undoStack.length <= 1) return;
    
    _redoStack.add(_undoStack.removeLast());
    final previousText = _undoStack.last;
    
    _controller.removeListener(_onTextChanged);
    _controller.text = previousText;
    _controller.addListener(_onTextChanged);
    
    _extractMentions();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    
    final nextText = _redoStack.removeLast();
    _undoStack.add(nextText);
    
    _controller.removeListener(_onTextChanged);
    _controller.text = nextText;
    _controller.addListener(_onTextChanged);
    
    _extractMentions();
  }

  void _onSubmitted(String text) {
    widget.onSubmitted?.call(text);
  }

  void _showPermissionError(MentionPermission permission) {
    String message;
    switch (permission) {
      case MentionPermission.blocked:
        message = 'You cannot mention this user (blocked)';
        break;
      case MentionPermission.restricted:
        message = 'You cannot mention this user (restricted)';
        break;
      case MentionPermission.notFound:
        message = 'User not found';
        break;
      case MentionPermission.allowed:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Public methods for external control
  void undo() => _undo();
  void redo() => _redo();
  
  List<ExtractedMention> get mentions => List.unmodifiable(_mentions);
  
  void clearMentions() {
    setState(() {
      _mentions.clear();
    });
    widget.onMentionsChanged?.call(_mentions);
  }
}

/// Extension for rich text display with mention highlighting
extension MentionRichText on String {
  Widget buildMentionRichText({
    TextStyle? style,
    TextStyle? mentionStyle,
    VoidCallback Function(String mentionId)? onMentionTap,
  }) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(this);
    
    if (matches.isEmpty) {
      return Text(this, style: style);
    }

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      // Add mention
      spans.add(TextSpan(
        text: match.group(0)!,
        style: mentionStyle ?? TextStyle(
          color: Colors.blue[600],
          fontWeight: FontWeight.w600,
        ),
        // Add tap handler if provided
        recognizer: onMentionTap != null
            ? (TapGestureRecognizer()
                ..onTap = () => onMentionTap(match.group(1)!))
            : null,
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < length) {
      spans.add(TextSpan(
        text: substring(lastMatchEnd),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
