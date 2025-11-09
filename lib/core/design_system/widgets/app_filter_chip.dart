import 'package:flutter/material.dart';

/// A filter chip widget using Material Design 3
///
/// Rest state: Shows emoji + label
/// Active state: Shows emoji + label + optional count badge
class AppFilterChip extends StatelessWidget {
  /// The emoji to display (e.g., '⚽️', '🎮')
  final String emoji;

  /// The label text (e.g., 'Football', 'All')
  final String label;

  /// Whether the chip is selected/active
  final bool isSelected;

  /// Callback when the chip is tapped
  final VoidCallback? onTap;

  /// Optional count to display in active state
  final int? count;

  /// Background color when selected
  final Color? selectedColor;

  /// Border color when selected (legacy compatibility)
  final Color? selectedBorderColor;

  /// Text color when selected (legacy compatibility)
  final Color? selectedTextColor;

  const AppFilterChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.count,
    this.selectedColor,
    this.selectedBorderColor,
    this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: selectedColor,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),

          // Label with overflow protection
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),

          // Count badge (only shown when selected and count is provided)
          if (isSelected && count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
