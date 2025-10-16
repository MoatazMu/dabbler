import 'package:flutter/material.dart';
import '../../../utils/enums/social_enums.dart';

/// Widget for filtering activity posts by type
/// Displays chips for each activity type with color-coded styling
class ActivityFilterWidget extends StatefulWidget {
  final List<PostActivityType> selectedTypes;
  final Function(List<PostActivityType>) onSelectionChanged;
  final bool showAllOption;
  
  const ActivityFilterWidget({
    super.key,
    required this.selectedTypes,
    required this.onSelectionChanged,
    this.showAllOption = true,
  });

  @override
  State<ActivityFilterWidget> createState() => _ActivityFilterWidgetState();
}

class _ActivityFilterWidgetState extends State<ActivityFilterWidget> {
  late List<PostActivityType> _selectedTypes;
  
  @override
  void initState() {
    super.initState();
    _selectedTypes = List.from(widget.selectedTypes);
  }
  
  @override
  void didUpdateWidget(ActivityFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTypes != widget.selectedTypes) {
      _selectedTypes = List.from(widget.selectedTypes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (widget.showAllOption) ...[
            _buildAllFilterChip(theme),
            const SizedBox(width: 8),
          ],
          ...PostActivityType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildActivityFilterChip(theme, type),
          )),
        ],
      ),
    );
  }
  
  Widget _buildAllFilterChip(ThemeData theme) {
    final isSelected = _selectedTypes.isEmpty || 
                      _selectedTypes.length == PostActivityType.values.length;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.all_inclusive,
            size: 16,
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
          ),
          const SizedBox(width: 4),
          Text(
            'All',
            style: TextStyle(
              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTypes = List.from(PostActivityType.values);
          } else {
            _selectedTypes.clear();
          }
        });
        widget.onSelectionChanged(_selectedTypes);
      },
      backgroundColor: theme.cardColor,
      selectedColor: theme.primaryColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? theme.primaryColor : theme.dividerColor,
        width: 1,
      ),
    );
  }
  
  Widget _buildActivityFilterChip(ThemeData theme, PostActivityType type) {
    final isSelected = _selectedTypes.contains(type);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.icon,
            size: 16,
            color: isSelected ? Colors.white : type.color,
          ),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: TextStyle(
              color: isSelected ? Colors.white : type.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTypes.add(type);
          } else {
            _selectedTypes.remove(type);
          }
        });
        widget.onSelectionChanged(_selectedTypes);
      },
      backgroundColor: type.color.withOpacity(0.1),
      selectedColor: type.color,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: type.color,
        width: 1,
      ),
    );
  }
}

/// Expandable activity filter widget with grouped sections
class ExpandableActivityFilterWidget extends StatefulWidget {
  final List<PostActivityType> selectedTypes;
  final Function(List<PostActivityType>) onSelectionChanged;
  
  const ExpandableActivityFilterWidget({
    super.key,
    required this.selectedTypes,
    required this.onSelectionChanged,
  });

  @override
  State<ExpandableActivityFilterWidget> createState() => _ExpandableActivityFilterWidgetState();
}

class _ExpandableActivityFilterWidgetState extends State<ExpandableActivityFilterWidget> {
  bool _isExpanded = false;
  late List<PostActivityType> _selectedTypes;
  
  @override
  void initState() {
    super.initState();
    _selectedTypes = List.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header with filter count and toggle
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activity Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedTypes.isNotEmpty && _selectedTypes.length < PostActivityType.values.length) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedTypes.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ],
            ),
          ),
        ),
        
        // Expandable filter content
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isExpanded ? null : 0,
          child: _isExpanded ? _buildExpandedContent(theme) : null,
        ),
      ],
    );
  }
  
  Widget _buildExpandedContent(ThemeData theme) {
    // Group activity types by category
    final socialActivities = [
      PostActivityType.originalPost,
      PostActivityType.comment,
    ];
    
    final venueActivities = [
      PostActivityType.venueRating,
      PostActivityType.checkIn,
      PostActivityType.venueBooking,
    ];
    
    final gameActivities = [
      PostActivityType.gameCreation,
      PostActivityType.gameJoin,
    ];
    
    final achievementActivities = [
      PostActivityType.achievement,
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions
          Row(
            children: [
              _buildQuickActionButton(
                'Select All',
                () {
                  setState(() {
                    _selectedTypes = List.from(PostActivityType.values);
                  });
                  widget.onSelectionChanged(_selectedTypes);
                },
                theme,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                'Clear All',
                () {
                  setState(() {
                    _selectedTypes.clear();
                  });
                  widget.onSelectionChanged(_selectedTypes);
                },
                theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activity type groups
          _buildActivityGroup('Social', socialActivities, theme),
          const SizedBox(height: 12),
          _buildActivityGroup('Venues', venueActivities, theme),
          const SizedBox(height: 12),
          _buildActivityGroup('Games', gameActivities, theme),
          const SizedBox(height: 12),
          _buildActivityGroup('Achievements', achievementActivities, theme),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    String label,
    VoidCallback onPressed,
    ThemeData theme,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.primaryColor,
        side: BorderSide(color: theme.primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
  
  Widget _buildActivityGroup(
    String title,
    List<PostActivityType> activities,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activities.map((type) => _buildActivityCheckbox(type, theme)).toList(),
        ),
      ],
    );
  }
  
  Widget _buildActivityCheckbox(PostActivityType type, ThemeData theme) {
    final isSelected = _selectedTypes.contains(type);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTypes.remove(type);
          } else {
            _selectedTypes.add(type);
          }
        });
        widget.onSelectionChanged(_selectedTypes);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? type.color.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? type.color : theme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: isSelected ? type.color : theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 8),
            Icon(
              type.icon,
              size: 16,
              color: isSelected ? type.color : theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 4),
            Text(
              type.displayName,
              style: TextStyle(
                color: isSelected ? type.color : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
