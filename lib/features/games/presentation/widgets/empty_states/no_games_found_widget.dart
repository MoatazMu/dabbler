import 'package:flutter/material.dart';

/// Empty state widget when no games are found in search/filters
class NoGamesFoundWidget extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClearFilters;
  final VoidCallback? onCreateGame;
  final String? customMessage;

  const NoGamesFoundWidget({
    super.key,
    this.searchQuery,
    this.onClearFilters,
    this.onCreateGame,
    this.customMessage,
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
                Icons.search_off_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'No games found',
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
            Column(
              children: [
                if (onClearFilters != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.clear_all_rounded),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCreateGame,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Game'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Help text
            Text(
              'Try adjusting your search criteria or create your own game to get started.',
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
    if (customMessage != null) {
      return customMessage!;
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return 'No games match your search for "$searchQuery". Try different keywords or adjust your filters.';
    }

    return 'There are no games matching your current filters. Try expanding your search criteria or create your own game.';
  }
}

/// Shimmer loading effect for the empty state
class NoGamesFoundShimmer extends StatelessWidget {
  const NoGamesFoundShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon shimmer
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title shimmer
            Container(
              width: 200,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Message shimmer
            Container(
              width: 300,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              width: 250,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Button shimmers
            Container(
              width: double.infinity,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
