import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

/// Notification preferences screen for social onboarding
class SocialOnboardingNotificationsScreen extends StatefulWidget {
  const SocialOnboardingNotificationsScreen({super.key});

  @override
  State<SocialOnboardingNotificationsScreen> createState() => _SocialOnboardingNotificationsScreenState();
}

class _SocialOnboardingNotificationsScreenState extends State<SocialOnboardingNotificationsScreen> {
  bool _friendRequests = true;
  bool _newMessages = true;
  bool _postLikes = true;
  bool _postComments = true;
  bool _gameInvites = true;
  bool _gameReminders = true;
  bool _weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 1.0, // Final step
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '4 of 4',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Header
            Icon(
              LucideIcons.bell,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Stay Updated',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              'Choose what notifications you\'d like to receive. You can always adjust these in settings.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Notification Settings
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Social',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationOption(
                    icon: LucideIcons.userPlus,
                    title: 'Friend Requests',
                    subtitle: 'When someone sends you a friend request',
                    value: _friendRequests,
                    onChanged: (value) {
                      setState(() {
                        _friendRequests = value;
                      });
                    },
                  ),
                  _buildNotificationOption(
                    icon: LucideIcons.messageCircle,
                    title: 'New Messages',
                    subtitle: 'When you receive a new message',
                    value: _newMessages,
                    onChanged: (value) {
                      setState(() {
                        _newMessages = value;
                      });
                    },
                  ),
                  _buildNotificationOption(
                    icon: LucideIcons.heart,
                    title: 'Post Likes',
                    subtitle: 'When someone likes your posts',
                    value: _postLikes,
                    onChanged: (value) {
                      setState(() {
                        _postLikes = value;
                      });
                    },
                  ),
                  _buildNotificationOption(
                    icon: LucideIcons.messageSquare,
                    title: 'Post Comments',
                    subtitle: 'When someone comments on your posts',
                    value: _postComments,
                    onChanged: (value) {
                      setState(() {
                        _postComments = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Games',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationOption(
                    icon: LucideIcons.calendar,
                    title: 'Game Invites',
                    subtitle: 'When you\'re invited to join a game',
                    value: _gameInvites,
                    onChanged: (value) {
                      setState(() {
                        _gameInvites = value;
                      });
                    },
                  ),
                  _buildNotificationOption(
                    icon: LucideIcons.clock,
                    title: 'Game Reminders',
                    subtitle: 'Reminders before your scheduled games',
                    value: _gameReminders,
                    onChanged: (value) {
                      setState(() {
                        _gameReminders = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Updates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationOption(
                    icon: LucideIcons.mail,
                    title: 'Weekly Digest',
                    subtitle: 'Weekly summary of your activity',
                    value: _weeklyDigest,
                    onChanged: (value) {
                      setState(() {
                        _weeklyDigest = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Save notification settings
                      context.push('/social/onboarding/complete');
                    },
                    child: const Text('Finish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: value ? Theme.of(context).primaryColor : Colors.grey,
        ),
      ),
    );
  }
}
