import 'package:flutter/material.dart';

enum GameCardVariant { compact, expanded }

class GameCard extends StatelessWidget {
  final String id;
  final String title;
  final String sport;
  final DateTime dateTime;
  final String venue;
  final int currentPlayers;
  final int maxPlayers;
  final String skillLevel;
  final double distance; // in km
  final double price;
  final String status; // 'open', 'filling_fast', 'almost_full', 'full', 'closed'
  final GameCardVariant variant;
  final VoidCallback? onTap;
  final bool isFeatured;

  const GameCard({
    super.key,
    required this.id,
    required this.title,
    required this.sport,
    required this.dateTime,
    required this.venue,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.skillLevel,
    required this.distance,
    required this.price,
    required this.status,
    this.variant = GameCardVariant.compact,
    this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Game card for $title, $sport, ${_formatDateTime()}, at $venue. $currentPlayers of $maxPlayers players.',
      button: onTap != null,
      child: Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFeatured ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: variant == GameCardVariant.compact
                ? _buildCompactLayout()
                : _buildExpandedLayout(),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with sport icon and status
        Row(
          children: [
            Semantics(
              label: 'Sport: $sport',
              child: _buildSportIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Status: ${_getStatusInfo().label}',
              child: _buildStatusBadge(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Details row
        Row(
          children: [
            Semantics(
              label: 'Players: $currentPlayers out of $maxPlayers',
              child: _buildPlayerCount(),
            ),
            const SizedBox(width: 16),
            Semantics(
              label: 'Skill level: $skillLevel',
              child: _buildSkillLevel(),
            ),
            const Spacer(),
            Semantics(
              label: price == 0 ? 'Free' : 'Price ${price.toStringAsFixed(0)} dollars',
              child: _buildPrice(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Venue and distance
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                venue,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              label: 'Distance ${distance.toStringAsFixed(1)} kilometers',
              child: _buildDistanceBadge(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with sport icon, title and featured badge
        Row(
          children: [
            _buildSportIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFeatured) _buildFeaturedBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 16),
        
        // Venue info
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                venue,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
            ),
            _buildDistanceBadge(),
          ],
        ),
        const SizedBox(height: 12),
        
        // Details grid
        Row(
          children: [
            Expanded(child: _buildPlayerCount()),
            const SizedBox(width: 16),
            Expanded(child: _buildSkillLevel()),
          ],
        ),
        const SizedBox(height: 12),
        
        // Price and additional info
        Row(
          children: [
            _buildPrice(),
            const Spacer(),
            if (_getStatusInfo().urgency != null)
              _buildUrgencyMessage(),
          ],
        ),
      ],
    );
  }

  Widget _buildSportIcon() {
    final sportData = _getSportData(sport);
    return Container(
      width: variant == GameCardVariant.compact ? 40 : 48,
      height: variant == GameCardVariant.compact ? 40 : 48,
      decoration: BoxDecoration(
        color: sportData['color'].withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        sportData['icon'],
        color: sportData['color'],
        size: variant == GameCardVariant.compact ? 20 : 24,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusInfo = _getStatusInfo();
    
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: 12, color: statusInfo.color),
          const SizedBox(width: 4),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );

    // Add animation for "filling fast" status
    if (status == 'filling_fast') {
      return TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 2),
        tween: Tween(begin: 0.3, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return AnimatedOpacity(
            opacity: value,
            duration: const Duration(milliseconds: 500),
            child: badge,
          );
        },
      );
    }
    
    return badge;
  }

  Widget _buildPlayerCount() {
    final percentage = currentPlayers / maxPlayers;
    Color progressColor;
    
    if (percentage >= 1.0) {
      progressColor = Colors.red;
    } else if (percentage >= 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '$currentPlayers/$maxPlayers',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          width: variant == GameCardVariant.compact ? 60 : 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillLevel() {
    final skillData = _getSkillLevelData(skillLevel);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: skillData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(skillData['icon'], size: 14, color: skillData['color']),
          const SizedBox(width: 4),
          Text(
            skillLevel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: skillData['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${distance.toStringAsFixed(1)}km',
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPrice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        price == 0 ? 'Free' : '\$${price.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: variant == GameCardVariant.compact ? 12 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'FEATURED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUrgencyMessage() {
    final statusInfo = _getStatusInfo();
    if (statusInfo.urgency == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(
        statusInfo.urgency!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.red[700],
        ),
      ),
    );
  }

  String _formatDateTime() {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    String dateStr;
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Tomorrow';
    } else if (difference < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dateStr = days[dateTime.weekday - 1];
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }
    
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$dateStr at $displayHour:$minute $amPm';
  }

  ({Color color, IconData icon, String label, String? urgency}) _getStatusInfo() {
    switch (status) {
      case 'open':
        return (
          color: Colors.green,
          icon: Icons.check_circle,
          label: 'Open',
          urgency: null,
        );
      case 'filling_fast':
        return (
          color: Colors.orange,
          icon: Icons.trending_up,
          label: 'Filling Fast',
          urgency: 'Join quickly!',
        );
      case 'almost_full':
        return (
          color: Colors.red,
          icon: Icons.warning,
          label: 'Almost Full',
          urgency: 'Only ${maxPlayers - currentPlayers} spots left',
        );
      case 'full':
        return (
          color: Colors.red,
          icon: Icons.block,
          label: 'Full',
          urgency: 'Join waitlist',
        );
      case 'closed':
        return (
          color: Colors.grey,
          icon: Icons.lock,
          label: 'Closed',
          urgency: null,
        );
      default:
        return (
          color: Colors.grey,
          icon: Icons.help,
          label: 'Unknown',
          urgency: null,
        );
    }
  }

  Map<String, dynamic> _getSportData(String sport) {
    switch (sport.toLowerCase()) {
      case 'soccer':
      case 'football':
        return {
          'icon': Icons.sports_soccer,
          'color': Colors.green,
        };
      case 'basketball':
        return {
          'icon': Icons.sports_basketball,
          'color': Colors.orange,
        };
      case 'tennis':
        return {
          'icon': Icons.sports_tennis,
          'color': Colors.blue,
        };
      case 'volleyball':
        return {
          'icon': Icons.sports_volleyball,
          'color': Colors.purple,
        };
      case 'baseball':
        return {
          'icon': Icons.sports_baseball,
          'color': Colors.brown,
        };
      default:
        return {
          'icon': Icons.sports,
          'color': Colors.grey,
        };
    }
  }

  Map<String, dynamic> _getSkillLevelData(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return {
          'icon': Icons.star_border,
          'color': Colors.green,
        };
      case 'intermediate':
        return {
          'icon': Icons.star_half,
          'color': Colors.orange,
        };
      case 'advanced':
        return {
          'icon': Icons.star,
          'color': Colors.red,
        };
      case 'professional':
        return {
          'icon': Icons.emoji_events,
          'color': Colors.purple,
        };
      default:
        return {
          'icon': Icons.help,
          'color': Colors.grey,
        };
    }
  }
}
