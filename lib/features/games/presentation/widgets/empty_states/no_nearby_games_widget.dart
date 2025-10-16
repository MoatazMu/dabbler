import 'package:flutter/material.dart';

/// Empty state widget when no games are found near the user's location
class NoNearbyGamesWidget extends StatelessWidget {
  final VoidCallback? onExpandRadius;
  final VoidCallback? onEnableLocation;
  final VoidCallback? onCreateGame;
  final VoidCallback? onViewAllGames;
  final bool locationEnabled;
  final double? currentRadius;

  const NoNearbyGamesWidget({
    super.key,
    this.onExpandRadius,
    this.onEnableLocation,
    this.onCreateGame,
    this.onViewAllGames,
    this.locationEnabled = true,
    this.currentRadius,
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
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                locationEnabled 
                    ? Icons.location_searching_rounded
                    : Icons.location_disabled_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              locationEnabled ? 'No games nearby' : 'Location disabled',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              _getMessage(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            if (locationEnabled) ..._buildLocationEnabledActions(context)
            else ..._buildLocationDisabledActions(context),
            
            const SizedBox(height: 24),
            
            // Help text
            Text(
              locationEnabled 
                  ? 'Games will appear here as they are created in your area.'
                  : 'Enable location services to find games near you.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getMessage() {
    if (!locationEnabled) {
      return 'Enable location services to discover games in your area and connect with nearby players.';
    }

    final radiusText = currentRadius != null 
        ? '${currentRadius!.round()} miles'
        : 'your area';

    return 'There are no games scheduled within $radiusText. Try expanding your search radius or be the first to create a game!';
  }

  List<Widget> _buildLocationEnabledActions(BuildContext context) {
    return [
      // Expand radius button
      if (onExpandRadius != null) ...[
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onExpandRadius,
            icon: const Icon(Icons.zoom_out_map_rounded),
            label: Text(
              currentRadius != null 
                  ? 'Expand to ${(currentRadius! * 2).round()} miles'
                  : 'Expand Search Area'
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Create game button
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onCreateGame,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Game'),
        ),
      ),

      const SizedBox(height: 12),

      // View all games button
      SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onViewAllGames,
          icon: const Icon(Icons.list_rounded),
          label: const Text('View All Games'),
        ),
      ),
    ];
  }

  List<Widget> _buildLocationDisabledActions(BuildContext context) {
    return [
      // Enable location button
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onEnableLocation,
          icon: const Icon(Icons.location_on_rounded),
          label: const Text('Enable Location'),
        ),
      ),

      const SizedBox(height: 12),

      // View all games button
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onViewAllGames,
          icon: const Icon(Icons.list_rounded),
          label: const Text('Browse All Games'),
        ),
      ),

      const SizedBox(height: 12),

      // Create game button
      SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onCreateGame,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Game'),
        ),
      ),
    ];
  }
}

/// Widget showing distance options for expanding search radius
class ExpandRadiusOptions extends StatelessWidget {
  final double currentRadius;
  final Function(double) onRadiusSelected;
  final VoidCallback onCancel;

  const ExpandRadiusOptions({
    super.key,
    required this.currentRadius,
    required this.onRadiusSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final radiusOptions = [
      currentRadius * 2,
      currentRadius * 3,
      currentRadius * 5,
      50.0, // Max radius
    ].where((radius) => radius > currentRadius).toSet().toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Expand Search Radius',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Current radius: ${currentRadius.round()} miles',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Radius options
          ...radiusOptions.map((radius) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onRadiusSelected(radius),
                child: Text('${radius.round()} miles'),
              ),
            ),
          )),
          
          const SizedBox(height: 16),
          
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
