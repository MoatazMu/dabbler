import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Action Cards Widget - Create Game and Join Game cards
class ActionCards extends StatelessWidget {
  const ActionCards({
    super.key,
    this.onCreateGameTap,
    this.onJoinGameTap,
  });

  final VoidCallback? onCreateGameTap;
  final VoidCallback? onJoinGameTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Create Game Card
        Expanded(
          child: _ActionCard(
            icon: Iconsax.add_copy,
            title: 'Create Game',
            subtitle: 'Start a new match',
            backgroundColor: const Color(0xFF3D2463),
            iconBackgroundColor: const Color(0xFF4A2F7A),
            onTap: onCreateGameTap,
          ),
        ),
        const SizedBox(width: 16),
        
        // Join Game Card
        Expanded(
          child: _ActionCard(
            icon: Iconsax.discover_copy,
            title: 'Join Game',
            subtitle: 'Find nearby games',
            backgroundColor: const Color(0xFF3D2463),
            iconBackgroundColor: const Color(0xFF3B4A5C),
            onTap: onJoinGameTap,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: iconBackgroundColor,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
