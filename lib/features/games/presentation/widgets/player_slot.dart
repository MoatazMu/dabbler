import 'package:flutter/material.dart';

enum PlayerStatus { confirmed, waitlisted, pending, checkedIn }
enum PlayerRole { player, captain, organizer }

class PlayerSlot extends StatelessWidget {
  final String? playerId;
  final String? playerName;
  final String? avatarUrl;
  final PlayerStatus? status;
  final PlayerRole role;
  final Color? teamColor;
  final bool isCurrentUser;
  final bool isEmpty;
  final VoidCallback? onTap;
  final bool showCheckInStatus;
  final bool isCheckedIn;

  const PlayerSlot({
    super.key,
    this.playerId,
    this.playerName,
    this.avatarUrl,
    this.status,
    this.role = PlayerRole.player,
    this.teamColor,
    this.isCurrentUser = false,
    this.isEmpty = false,
    this.onTap,
    this.showCheckInStatus = false,
    this.isCheckedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return _buildEmptySlot(context);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatarSection(context),
            const SizedBox(height: 6),
            _buildPlayerInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Open Spot',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return Stack(
      children: [
        _buildAvatar(context),
        _buildStatusIndicators(context),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    Widget avatar;
    
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to initials
        },
        child: avatarUrl!.isEmpty ? _buildInitialsAvatar() : null,
      );
    } else {
      avatar = _buildInitialsAvatar();
    }

    // Add team color border if specified
    if (teamColor != null) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: teamColor!,
            width: 3,
          ),
        ),
        child: avatar,
      );
    }

    // Add glow effect for current user
    if (isCurrentUser) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitialsAvatar() {
    final initials = playerName != null && playerName!.isNotEmpty
        ? playerName!.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 28,
      backgroundColor: _getAvatarBackgroundColor(),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Column(
        children: [
          // Role badge
          if (role != PlayerRole.player) _buildRoleBadge(),
          
          // Check-in status
          if (showCheckInStatus) _buildCheckInBadge(),
          
          // Player status
          if (status != null) _buildPlayerStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    IconData icon;
    Color color;
    
    switch (role) {
      case PlayerRole.captain:
        icon = Icons.star;
        color = Colors.amber;
        break;
      case PlayerRole.organizer:
        icon = Icons.admin_panel_settings;
        color = Colors.blue;
        break;
      case PlayerRole.player:
        return const SizedBox.shrink();
    }

    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 12,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCheckInBadge() {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isCheckedIn ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        isCheckedIn ? Icons.check : Icons.access_time,
        size: 10,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPlayerStatusBadge() {
    Color color;
    IconData icon;
    
    switch (status!) {
      case PlayerStatus.confirmed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case PlayerStatus.waitlisted:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case PlayerStatus.pending:
        color = Colors.grey;
        icon = Icons.schedule;
        break;
      case PlayerStatus.checkedIn:
        color = Colors.blue;
        icon = Icons.login;
        break;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 8,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context) {
    return Column(
      children: [
        // Player name
        SizedBox(
          width: 72,
          child: Text(
            isEmpty ? 'Open Spot' : (playerName ?? 'Unknown'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              color: isEmpty 
                  ? Colors.grey[600]
                  : isCurrentUser 
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Status text
        if (status != null && !isEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _getStatusText(status!),
            style: TextStyle(
              fontSize: 10,
              color: _getStatusColor(status!),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        // Team assignment
        if (teamColor != null && !isEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }

  Color _getAvatarBackgroundColor() {
    if (playerName == null || playerName!.isEmpty) {
      return Colors.grey;
    }
    
    // Generate color based on name hash
    final hash = playerName!.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    return colors[hash.abs() % colors.length];
  }

  String _getStatusText(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.confirmed:
        return 'Confirmed';
      case PlayerStatus.waitlisted:
        return 'Waitlisted';
      case PlayerStatus.pending:
        return 'Pending';
      case PlayerStatus.checkedIn:
        return 'Checked In';
    }
  }

  Color _getStatusColor(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.confirmed:
        return Colors.green;
      case PlayerStatus.waitlisted:
        return Colors.orange;
      case PlayerStatus.pending:
        return Colors.grey;
      case PlayerStatus.checkedIn:
        return Colors.blue;
    }
  }
}
