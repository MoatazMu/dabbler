import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/user_progress.dart';

class ProgressFilterChips extends StatelessWidget {
  final ProgressStatus? selectedStatus;
  final ValueChanged<ProgressStatus?> onStatusChanged;
  final List<ProgressStatus> availableStatuses;
  final bool showCounts;
  final Map<ProgressStatus, int>? statusCounts;

  const ProgressFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.availableStatuses,
    this.showCounts = false,
    this.statusCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All filter chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.all_inclusive, size: 16),
                  const SizedBox(width: 6),
                  const Text('All'),
                  if (showCounts && statusCounts != null)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selectedStatus == null
                            ? Colors.white.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getTotalCount().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selectedStatus == null
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              selected: selectedStatus == null,
              onSelected: (selected) {
                if (selected) onStatusChanged(null);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: selectedStatus == null
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                fontWeight: selectedStatus == null
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ).animate()
              .fadeIn(duration: 200.ms)
              .slideX(
                begin: -0.3,
                end: 0,
                duration: 200.ms,
                curve: Curves.easeOutCubic,
              ),
          ),
          
          // Status filter chips
          ...availableStatuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isSelected = selectedStatus == status;
            final count = statusCounts?[status] ?? 0;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 16,
                      color: isSelected ? Colors.white : _getStatusColor(status),
                    ),
                    const SizedBox(width: 6),
                    Text(_getStatusName(status)),
                    if (showCounts && count > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : _getStatusColor(status),
                          ),
                        ),
                      ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  onStatusChanged(selected ? status : null);
                },
                selectedColor: _getStatusColor(status),
                backgroundColor: Colors.grey[100],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _getStatusColor(status),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ).animate()
                .fadeIn(
                  duration: 200.ms,
                  delay: Duration(milliseconds: index * 50),
                )
                .slideX(
                  begin: -0.3,
                  end: 0,
                  duration: 200.ms,
                  delay: Duration(milliseconds: index * 50),
                  curve: Curves.easeOutCubic,
                ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.notStarted:
        return Icons.radio_button_unchecked;
      case ProgressStatus.inProgress:
        return Icons.timelapse;
      case ProgressStatus.completed:
        return Icons.check_circle;
      case ProgressStatus.expired:
        return Icons.schedule_outlined;
    }
  }

  String _getStatusName(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.notStarted:
        return 'Not Started';
      case ProgressStatus.inProgress:
        return 'In Progress';
      case ProgressStatus.completed:
        return 'Completed';
      case ProgressStatus.expired:
        return 'Expired';
    }
  }

  Color _getStatusColor(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.notStarted:
        return Colors.grey;
      case ProgressStatus.inProgress:
        return Colors.orange;
      case ProgressStatus.completed:
        return Colors.green;
      case ProgressStatus.expired:
        return Colors.red;
    }
  }

  int _getTotalCount() {
    if (statusCounts == null) return 0;
    return statusCounts!.values.fold(0, (sum, count) => sum + count);
  }
}