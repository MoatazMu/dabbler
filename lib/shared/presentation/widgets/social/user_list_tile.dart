import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../utils/enums/social_enums.dart';

/// Swipe action for user list tile
class SwipeAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? backgroundColor;
  
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.backgroundColor,
  });
}

/// Loading state type for shimmer effect
enum LoadingState {
  none,
  loading,
  error,
  success,
}
/// Flexible user tile widget for various social contexts
class UserListTile extends StatefulWidget {
  /// The user to display
  final UserProfile? user;
  /// Primary text (usually display name or username)
  final String? primaryText;
  
  /// Secondary text (usually status or subtitle)
  final String? secondaryText;
  
  /// Avatar URL override
  final String? avatarUrl;
  
  /// Show online status overlay on avatar
  final bool showOnlineStatus;
  
  /// Online status of the user
  final OnlineStatus? onlineStatus;
  
  /// Trailing widget (action buttons, etc.)
  final Widget? trailing;
  
  /// Swipe actions (message, view, remove, etc.)
  final List<SwipeAction>? swipeActions;
  
  /// Main tap handler
  final VoidCallback? onTap;
  
  /// Long press handler
  final VoidCallback? onLongPress;
  
  /// Loading state for shimmer effect
  final LoadingState loadingState;
  
  /// Error message for error state
  final String? errorMessage;
  
  /// Retry callback for error state
  final VoidCallback? onRetry;
  
  /// Custom padding
  final EdgeInsetsGeometry? padding;
  /// Custom background color
  final Color? backgroundColor;
  
  /// Enable/disable the tile
  final bool enabled;
  
  /// Show divider below tile
  final bool showDivider;
  
  /// Custom avatar size
  final double avatarSize;
  
  final bool dense;
  
  /// Semantic label for accessibility
  final String? semanticLabel;
  
  const UserListTile({
    super.key,
    required this.user,
    required this.onTap,
    this.primaryText,
    this.secondaryText,
    this.avatarUrl,
    this.showOnlineStatus = false,
    this.onlineStatus,
    this.trailing,
    this.swipeActions,
    this.onLongPress,
    this.loadingState = LoadingState.none,
    this.errorMessage,
    this.onRetry,
    this.padding,
    this.backgroundColor,
    this.enabled = true,
    this.showDivider = false,
    this.avatarSize = 40.0,
    this.dense = false,
    this.semanticLabel,
  });

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? _getSemanticLabel(),
      child: Column(
        children: [
          _buildTileContent(),
          if (widget.showDivider) const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildTileContent() {
    if (widget.loadingState == LoadingState.loading) {
      return _buildShimmerTile();
    }

    if (widget.loadingState == LoadingState.error) {
      return _buildErrorTile();
    }

    return _buildNormalTile();
  }

  Widget _buildNormalTile() {
    Widget tile = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        color: widget.backgroundColor,
        padding: widget.padding ?? EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: widget.dense ? 8.0 : 12.0,
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextContent(),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 16),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    // Wrap with swipe actions if provided
    if (widget.swipeActions != null && widget.swipeActions!.isNotEmpty) {
      tile = _buildSwipeableTile(tile);
    }

    // Wrap with gesture detector for tap handling
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      onTapDown: widget.enabled ? (_) => _handleTapDown() : null,
      onTapUp: widget.enabled ? (_) => _handleTapUp() : null,
      onTapCancel: widget.enabled ? () => _handleTapUp() : null,
      child: tile,
    );
  }

  Widget _buildSwipeableTile(Widget child) {
    return Dismissible(
      key: Key('user_tile_${widget.user?.id ?? 'unknown'}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        // Don't actually dismiss, just show actions
        _showSwipeActions();
        return false;
      },
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.message, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: child,
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = widget.avatarUrl ?? widget.user?.avatarUrl;
    final initials = _getInitials();

    return Stack(
      children: [
        CircleAvatar(
          radius: widget.avatarSize / 2,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          backgroundColor: widget.enabled
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.grey[300],
          child: avatarUrl == null
              ? Text(
                  initials,
                  style: TextStyle(
                    fontSize: widget.avatarSize / 3,
                    fontWeight: FontWeight.bold,
                    color: widget.enabled
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                )
              : null,
        ),
        if (widget.showOnlineStatus && widget.onlineStatus != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildOnlineStatusIndicator(),
          ),
      ],
    );
  }

  Widget _buildOnlineStatusIndicator() {
    Color statusColor;
    switch (widget.onlineStatus!) {
      case OnlineStatus.online:
        statusColor = Colors.green;
        break;
      case OnlineStatus.away:
        statusColor = Colors.orange;
        break;
      case OnlineStatus.busy:
        statusColor = Colors.red;
        break;
      case OnlineStatus.offline:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    final primaryText = widget.primaryText ??
        widget.user?.displayName ??
        'Unknown User';
    
    final secondaryText = widget.secondaryText ??
        widget.user?.bio ??
        '@${widget.user?.email ?? 'email'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryText,
          style: TextStyle(
            fontSize: widget.dense ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: widget.enabled
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (secondaryText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            secondaryText,
            style: TextStyle(
              fontSize: widget.dense ? 12 : 14,
              color: widget.enabled
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildShimmerTile() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      child: Row(
        children: [
          _buildShimmerAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 150, height: 16),
                const SizedBox(height: 4),
                _buildShimmerBox(width: 200, height: 14),
              ],
            ),
          ),
          _buildShimmerBox(width: 40, height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmerAvatar() {
    return Container(
      width: widget.avatarSize,
      height: widget.avatarSize,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildErrorTile() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: widget.avatarSize,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load user',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRetry,
              tooltip: 'Retry',
            ),
        ],
      ),
    );
  }

  String _getInitials() {
    final name = widget.primaryText ??
        widget.user?.displayName ??
        'U';
    
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words.first.substring(0, 1).toUpperCase()}'
          '${words.last.substring(0, 1).toUpperCase()}';
    }
    
    return name.substring(0, 1).toUpperCase();
  }

  String _getSemanticLabel() {
    final primaryText = widget.primaryText ??
        widget.user?.displayName ??
        'Unknown User';
    
    final secondaryText = widget.secondaryText ??
        widget.user?.bio ??
        '';

    String label = primaryText;
    if (secondaryText.isNotEmpty) {
      label += ', $secondaryText';
    }

    if (widget.showOnlineStatus && widget.onlineStatus != null) {
      label += ', ${widget.onlineStatus!.name}';
    }

    return label;
  }

  void _handleTapDown() {
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp() {
    _animationController.reverse();
  }

  void _showSwipeActions() {
    if (widget.swipeActions == null || widget.swipeActions!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.swipeActions!.map((action) => ListTile(
            leading: Icon(action.icon, color: action.color),
            title: Text(action.label),
            onTap: () {
              Navigator.of(context).pop();
              action.onTap();
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Extension for easy creation of common user list tiles
extension UserListTileExtensions on UserListTile {
  /// Create a friend request tile
  static UserListTile friendRequest({
    required UserProfile user,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    VoidCallback? onTap,
  }) {
    return UserListTile(
      user: user,
      secondaryText: 'Wants to be your friend',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: onAccept,
            tooltip: 'Accept',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onDecline,
            tooltip: 'Decline',
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  /// Create a search result tile
  static UserListTile searchResult({
    required UserProfile user,
    String? highlightText,
    VoidCallback? onTap,
  }) {
    return UserListTile(
      user: user,
      showOnlineStatus: true,
      onTap: onTap,
      swipeActions: [
        SwipeAction(
          icon: Icons.message,
          label: 'Message',
          color: Colors.blue,
          onTap: () {
            // Handle message action
          },
        ),
        SwipeAction(
          icon: Icons.person_add,
          label: 'Add Friend',
          color: Colors.green,
          onTap: () {
            // Handle add friend action
          },
        ),
      ],
    );
  }

  /// Create a blocked user tile
  static UserListTile blockedUser({
    required UserProfile user,
    required VoidCallback onUnblock,
    VoidCallback? onTap,
  }) {
    return UserListTile(
      user: user,
      secondaryText: 'Blocked',
      enabled: false,
      trailing: TextButton(
        onPressed: onUnblock,
        child: const Text('Unblock'),
      ),
      onTap: onTap,
    );
  }
}
