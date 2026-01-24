import 'package:flutter/material.dart';

import 'package:dabbler/data/models/venue_submission_model.dart';

class VenueSubmissionStatusBadge extends StatelessWidget {
  final VenueSubmissionStatus status;

  const VenueSubmissionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (bg, fg) = switch (status) {
      VenueSubmissionStatus.draft => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      VenueSubmissionStatus.pending => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      VenueSubmissionStatus.approved => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      VenueSubmissionStatus.returned => (scheme.errorContainer, scheme.onErrorContainer),
      VenueSubmissionStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer),
    };

    final label = status.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
