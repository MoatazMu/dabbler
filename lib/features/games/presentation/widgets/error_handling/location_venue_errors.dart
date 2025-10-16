import 'package:flutter/material.dart';

/// Error widget for location permission denied
class LocationPermissionErrorWidget extends StatelessWidget {
  final VoidCallback? onEnableLocation;
  final VoidCallback? onBrowseWithoutLocation;
  final VoidCallback? onOpenSettings;
  final bool isPermanentlyDenied;

  const LocationPermissionErrorWidget({
    super.key,
    this.onEnableLocation,
    this.onBrowseWithoutLocation,
    this.onOpenSettings,
    this.isPermanentlyDenied = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Location icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 64,
                color: theme.colorScheme.tertiary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Location Access Needed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              isPermanentlyDenied
                  ? 'To find games near you, please enable location access in your device settings.'
                  : 'Dabbler needs location access to show you games and venues in your area.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Enable location button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isPermanentlyDenied ? onOpenSettings : onEnableLocation,
                icon: const Icon(Icons.location_on_rounded),
                label: Text(isPermanentlyDenied ? 'Open Settings' : 'Enable Location'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Browse without location
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBrowseWithoutLocation,
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Browse All Games'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Benefits info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Why we need location:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Find games and venues near you\n'
                    '• Get accurate travel times\n'
                    '• Receive location-based notifications',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

/// Error widget for venue unavailability
class VenueUnavailableErrorWidget extends StatelessWidget {
  final VoidCallback? onChooseDifferentVenue;
  final VoidCallback? onChooseDifferentTime;
  final VoidCallback? onContactVenue;
  final String? venueName;
  final String? reason;
  final DateTime? availableFrom;

  const VenueUnavailableErrorWidget({
    super.key,
    this.onChooseDifferentVenue,
    this.onChooseDifferentTime,
    this.onContactVenue,
    this.venueName,
    this.reason,
    this.availableFrom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Venue unavailable icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.place_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Venue Unavailable',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              venueName != null
                  ? 'Sorry, $venueName is not available at your selected time.'
                  : 'This venue is not available at your selected time.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Reason or availability info
            if (reason != null || availableFrom != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (reason != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (reason != null && availableFrom != null)
                      const SizedBox(height: 8),
                    if (availableFrom != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Next available: ${_formatDateTime(availableFrom!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Choose different time
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onChooseDifferentTime,
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Choose Different Time'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Choose different venue
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onChooseDifferentVenue,
                icon: const Icon(Icons.place_rounded),
                label: const Text('Choose Different Venue'),
              ),
            ),
            
            // Contact venue (if available)
            if (onContactVenue != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onContactVenue,
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Contact Venue'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (date == today) {
      dateStr = 'Today';
    } else if (date == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.month}/${dateTime.day}';
    }
    
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    
    return '$dateStr at $displayHour:$minuteStr $period';
  }
}

/// Generic error widget with customizable content
class CustomGameErrorWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<GameErrorAction> actions;
  final Widget? additionalContent;
  final Color? iconColor;

  const CustomGameErrorWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.additionalContent,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.error;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: effectiveIconColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Additional content
            if (additionalContent != null) ...[
              const SizedBox(height: 16),
              additionalContent!,
            ],
            
            const SizedBox(height: 32),
            
            // Action buttons
            ...actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              
              Widget button;
              switch (action.style) {
                case GameErrorActionStyle.filled:
                  button = FilledButton.icon(
                    onPressed: action.onPressed,
                    icon: action.icon != null ? Icon(action.icon) : const SizedBox.shrink(),
                    label: Text(action.label),
                  );
                  break;
                case GameErrorActionStyle.outlined:
                  button = OutlinedButton.icon(
                    onPressed: action.onPressed,
                    icon: action.icon != null ? Icon(action.icon) : const SizedBox.shrink(),
                    label: Text(action.label),
                  );
                  break;
                case GameErrorActionStyle.text:
                  button = TextButton.icon(
                    onPressed: action.onPressed,
                    icon: action.icon != null ? Icon(action.icon) : const SizedBox.shrink(),
                    label: Text(action.label),
                  );
                  break;
              }
              
              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: button,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Action configuration for custom error widgets
class GameErrorAction {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GameErrorActionStyle style;

  const GameErrorAction({
    required this.label,
    this.onPressed,
    this.icon,
    this.style = GameErrorActionStyle.filled,
  });
}

enum GameErrorActionStyle {
  filled,
  outlined,
  text,
}
