import 'package:flutter/material.dart';

/// Error widget for network-related game loading failures
class GameNetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;
  final bool isOffline;

  const GameNetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
    this.isOffline = false,
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
            // Error icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline 
                    ? Icons.wifi_off_rounded
                    : Icons.cloud_off_rounded,
                size: 64,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error title
            Text(
              isOffline ? 'No internet connection' : 'Connection failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Error message
            Text(
              customMessage ??
                  (isOffline
                      ? 'Check your internet connection and try again.'
                      : 'Unable to load games. Please check your connection and try again.'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Retry button
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Help text
            Text(
              isOffline
                  ? 'Games you\'ve joined will sync when you\'re back online.'
                  : 'If the problem persists, please try again later.',
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
}

/// Error widget for when a game is full
class GameFullErrorWidget extends StatelessWidget {
  final VoidCallback? onViewOtherGames;
  final VoidCallback? onJoinWaitlist;
  final VoidCallback? onCreateSimilar;
  final bool hasWaitlist;
  final String? gameName;

  const GameFullErrorWidget({
    super.key,
    this.onViewOtherGames,
    this.onJoinWaitlist,
    this.onCreateSimilar,
    this.hasWaitlist = true,
    this.gameName,
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
            // Full icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_rounded,
                size: 64,
                color: theme.colorScheme.tertiary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Game is Full',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              gameName != null
                  ? 'Sorry, "$gameName" has reached its player limit. But don\'t worry - there are other ways to get in the game!'
                  : 'This game has reached its player limit. Don\'t worry - there are other ways to get in the game!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Join waitlist button (primary action if available)
            if (hasWaitlist && onJoinWaitlist != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onJoinWaitlist,
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('Join Waitlist'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // View other games
            SizedBox(
              width: double.infinity,
              child: hasWaitlist ? OutlinedButton.icon(
                onPressed: onViewOtherGames,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Find Similar Games'),
              ) : FilledButton.icon(
                onPressed: onViewOtherGames,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Find Similar Games'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Create similar game
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onCreateSimilar,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Similar Game'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info box
            if (hasWaitlist)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'ll be notified if a spot opens up. Waitlist members are added in order.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

/// Error widget for booking conflicts
class BookingConflictErrorWidget extends StatelessWidget {
  final VoidCallback? onViewConflicts;
  final VoidCallback? onChooseDifferentTime;
  final VoidCallback? onContinueAnyway;
  final List<String>? conflictingGames;
  final bool canContinue;

  const BookingConflictErrorWidget({
    super.key,
    this.onViewConflicts,
    this.onChooseDifferentTime,
    this.onContinueAnyway,
    this.conflictingGames,
    this.canContinue = false,
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
            // Conflict icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Schedule Conflict',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              conflictingGames?.isNotEmpty == true
                  ? 'This game conflicts with your existing bookings:'
                  : 'You already have a game scheduled at this time.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Conflicting games list
            if (conflictingGames?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: conflictingGames!.map((game) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            game,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Primary action - Choose different time
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onChooseDifferentTime,
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Choose Different Time'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // View conflicts
            if (onViewConflicts != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewConflicts,
                  icon: const Icon(Icons.event_rounded),
                  label: const Text('View My Schedule'),
                ),
              ),
            
            // Continue anyway (if allowed)
            if (canContinue && onContinueAnyway != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onContinueAnyway,
                  icon: Icon(
                    Icons.warning_rounded,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Book Anyway',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error widget for payment failures
class PaymentErrorWidget extends StatelessWidget {
  final VoidCallback? onRetryPayment;
  final VoidCallback? onChangePlan;
  final VoidCallback? onContactSupport;
  final String? errorMessage;
  final bool canRetry;

  const PaymentErrorWidget({
    super.key,
    this.onRetryPayment,
    this.onChangePlan,
    this.onContactSupport,
    this.errorMessage,
    this.canRetry = true,
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
            // Payment error icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Payment Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Error message
            Text(
              errorMessage ?? 'There was a problem processing your payment. Please try again or contact support.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Retry payment
            if (canRetry && onRetryPayment != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetryPayment,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Payment'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Change plan/payment method
            if (onChangePlan != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onChangePlan,
                  icon: const Icon(Icons.credit_card_rounded),
                  label: const Text('Change Payment Method'),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Contact support
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onContactSupport,
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Contact Support'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your game spot is temporarily reserved. Complete payment within 10 minutes to secure it.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
