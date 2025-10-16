/// Multi-choice field with chip-based selection and advanced features
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Choice item for multi-selection
class ChoiceItem<T> {
  final T value;
  final String label;
  final String? description;
  final IconData? icon;
  final Color? color;
  final String? category;
  final bool enabled;
  final Widget? customWidget;
  
  const ChoiceItem({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.color,
    this.category,
    this.enabled = true,
    this.customWidget,
  });
  
  ChoiceItem<T> copyWith({
    T? value,
    String? label,
    String? description,
    IconData? icon,
    Color? color,
    String? category,
    bool? enabled,
    Widget? customWidget,
  }) {
    return ChoiceItem<T>(
      value: value ?? this.value,
      label: label ?? this.label,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
      customWidget: customWidget ?? this.customWidget,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChoiceItem &&
          runtimeType == other.runtimeType &&
          value == other.value;
  
  @override
  int get hashCode => value.hashCode;
}

/// Selection limit configuration
class SelectionLimit {
  final int? maxSelections;
  final int? minSelections;
  final String? maxExceededMessage;
  final String? minNotMetMessage;
  
  const SelectionLimit({
    this.maxSelections,
    this.minSelections,
    this.maxExceededMessage,
    this.minNotMetMessage,
  });
  
  bool isValidSelection(int currentCount) {
    if (minSelections != null && currentCount < minSelections!) return false;
    if (maxSelections != null && currentCount > maxSelections!) return false;
    return true;
  }
  
  String? getValidationMessage(int currentCount) {
    if (minSelections != null && currentCount < minSelections!) {
      return minNotMetMessage ?? 'Please select at least $minSelections items';
    }
    if (maxSelections != null && currentCount > maxSelections!) {
      return maxExceededMessage ?? 'Maximum $maxSelections items allowed';
    }
    return null;
  }
}

/// Chip styling configuration
class ChipStyling {
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final double spacing;
  final double runSpacing;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool showCheckmark;
  final bool showDeleteIcon;
  
  const ChipStyling({
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.spacing = 8.0,
    this.runSpacing = 4.0,
    this.borderRadius,
    this.elevation = 2.0,
    this.showCheckmark = true,
    this.showDeleteIcon = false,
  });
}

/// Multi-choice field with chip-based selection
class MultiChoiceField<T> extends StatefulWidget {
  final List<ChoiceItem<T>> items;
  final List<T> selectedValues;
  final ValueChanged<List<T>>? onSelectionChanged;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool searchable;
  final String? searchHint;
  final SelectionLimit? selectionLimit;
  final ChipStyling chipStyling;
  final bool groupByCategory;
  final bool reorderable;
  final bool showSelectAll;
  final bool showClearAll;
  final String? selectAllText;
  final String? clearAllText;
  final Widget? emptyState;
  final Widget? searchEmptyState;
  final EdgeInsets padding;
  final TextStyle? labelStyle;
  final TextStyle? categoryStyle;
  final int? maxDisplayedItems;
  final Widget Function(int hiddenCount)? hiddenItemsBuilder;
  final bool enableHapticFeedback;
  final Duration animationDuration;
  
  const MultiChoiceField({
    super.key,
    required this.items,
    required this.selectedValues,
    this.onSelectionChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.searchable = false,
    this.searchHint = 'Search...',
    this.selectionLimit,
    this.chipStyling = const ChipStyling(),
    this.groupByCategory = false,
    this.reorderable = false,
    this.showSelectAll = false,
    this.showClearAll = false,
    this.selectAllText = 'Select All',
    this.clearAllText = 'Clear All',
    this.emptyState,
    this.searchEmptyState,
    this.padding = const EdgeInsets.all(16),
    this.labelStyle,
    this.categoryStyle,
    this.maxDisplayedItems,
    this.hiddenItemsBuilder,
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });
  
  @override
  State<MultiChoiceField<T>> createState() => _MultiChoiceFieldState<T>();
}

class _MultiChoiceFieldState<T> extends State<MultiChoiceField<T>>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  List<ChoiceItem<T>> _filteredItems = [];
  List<T> _selectedValues = [];
  late AnimationController _animationController;
  final Map<T, AnimationController> _chipControllers = {};
  String _validationMessage = '';
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedValues = List.from(widget.selectedValues);
    _filteredItems = List.from(widget.items);
    
    _setupAnimations();
    _searchController.addListener(_onSearchChanged);
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Initialize chip animations
    for (final item in widget.items) {
      _chipControllers[item.value] = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
      
      if (_selectedValues.contains(item.value)) {
        _chipControllers[item.value]!.value = 1.0;
      }
    }
  }
  
  @override
  void didUpdateWidget(MultiChoiceField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.selectedValues != oldWidget.selectedValues) {
      _selectedValues = List.from(widget.selectedValues);
      _updateChipAnimations();
    }
    
    if (widget.items != oldWidget.items) {
      _filteredItems = List.from(widget.items);
      _setupAnimations();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    for (final controller in _chipControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: widget.labelStyle ?? 
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          
          if (widget.searchable) ...[
            _buildSearchField(),
            const SizedBox(height: 12),
          ],
          
          if (widget.showSelectAll || widget.showClearAll) ...[
            _buildActionButtons(),
            const SizedBox(height: 12),
          ],
          
          if (_selectedValues.isNotEmpty && !widget.reorderable) ...[
            _buildSelectedSummary(),
            const SizedBox(height: 8),
          ],
          
          if (widget.reorderable && _selectedValues.isNotEmpty) ...[
            _buildReorderableSelected(),
            const SizedBox(height: 12),
          ],
          
          _buildChoiceChips(),
          
          if (_validationMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildValidationMessage(),
          ],
          
          if (widget.helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.showSelectAll)
          OutlinedButton.icon(
            onPressed: widget.enabled ? _selectAll : null,
            icon: const Icon(Icons.select_all),
            label: Text(widget.selectAllText!),
          ),
        
        if (widget.showSelectAll && widget.showClearAll)
          const SizedBox(width: 8),
        
        if (widget.showClearAll)
          OutlinedButton.icon(
            onPressed: widget.enabled && _selectedValues.isNotEmpty ? _clearAll : null,
            icon: const Icon(Icons.clear_all),
            label: Text(widget.clearAllText!),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        
        const Spacer(),
        
        if (_selectedValues.isNotEmpty)
          Text(
            '${_selectedValues.length} selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
  
  Widget _buildSelectedSummary() {
    if (_selectedValues.isEmpty) return const SizedBox.shrink();
    
    final selectedItems = widget.items
        .where((item) => _selectedValues.contains(item.value))
        .toList();
    
    final displayItems = widget.maxDisplayedItems != null
        ? selectedItems.take(widget.maxDisplayedItems!)
        : selectedItems;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected (${_selectedValues.length}):',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            ...displayItems.map((item) => Chip(
              label: Text(
                item.label,
                style: const TextStyle(fontSize: 12),
              ),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: widget.enabled ? () => _toggleSelection(item.value) : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )),
            
            if (widget.maxDisplayedItems != null && 
                selectedItems.length > widget.maxDisplayedItems!)
              widget.hiddenItemsBuilder?.call(selectedItems.length - widget.maxDisplayedItems!) ??
                  Chip(
                    label: Text(
                      '+${selectedItems.length - widget.maxDisplayedItems!} more',
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildReorderableSelected() {
    if (_selectedValues.isEmpty) return const SizedBox.shrink();
    
    final selectedItems = _selectedValues
        .map((value) => widget.items.firstWhere((item) => item.value == value))
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected (${_selectedValues.length}) - Drag to reorder:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        
        ReorderableWrap(
          spacing: 8,
          runSpacing: 4,
          children: selectedItems.map((item) {
            return Chip(
              key: ValueKey(item.value),
              label: Text(item.label),
              avatar: const Icon(Icons.drag_handle, size: 16),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: widget.enabled ? () => _toggleSelection(item.value) : null,
            );
          }).toList(),
          onReorder: (oldIndex, newIndex) {
            if (!widget.enabled) return;
            
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _selectedValues.removeAt(oldIndex);
              _selectedValues.insert(newIndex, item);
            });
            
            widget.onSelectionChanged?.call(_selectedValues);
          },
        ),
      ],
    );
  }
  
  Widget _buildChoiceChips() {
    if (_filteredItems.isEmpty) {
      return widget.emptyState ??
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No items available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
    }
    
    if (widget.searchable && 
        _searchController.text.isNotEmpty && 
        _filteredItems.isEmpty) {
      return widget.searchEmptyState ??
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No items match "${_searchController.text}"',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
    }
    
    if (widget.groupByCategory) {
      return _buildGroupedChips();
    } else {
      return _buildFlatChips();
    }
  }
  
  Widget _buildFlatChips() {
    return Wrap(
      spacing: widget.chipStyling.spacing,
      runSpacing: widget.chipStyling.runSpacing,
      children: _filteredItems.map((item) => _buildChoiceChip(item)).toList(),
    );
  }
  
  Widget _buildGroupedChips() {
    final groupedItems = <String, List<ChoiceItem<T>>>{};
    
    for (final item in _filteredItems) {
      final category = item.category ?? 'Other';
      groupedItems.putIfAbsent(category, () => []).add(item);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: widget.categoryStyle ??
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
              ),
            ),
            
            Wrap(
              spacing: widget.chipStyling.spacing,
              runSpacing: widget.chipStyling.runSpacing,
              children: entry.value.map((item) => _buildChoiceChip(item)).toList(),
            ),
            
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildChoiceChip(ChoiceItem<T> item) {
    final isSelected = _selectedValues.contains(item.value);
    final controller = _chipControllers[item.value];
    
    if (item.customWidget != null) {
      return GestureDetector(
        onTap: widget.enabled && item.enabled ? () => _toggleSelection(item.value) : null,
        child: item.customWidget!,
      );
    }
    
    return AnimatedBuilder(
      animation: controller ?? _animationController,
      builder: (context, child) {
        final scale = controller?.value ?? 1.0;
        
        return Transform.scale(
          scale: 0.9 + (scale * 0.1),
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 16,
                    color: isSelected 
                        ? widget.chipStyling.selectedTextColor
                        : widget.chipStyling.unselectedTextColor,
                  ),
                  const SizedBox(width: 4),
                ],
                
                Text(
                  item.label,
                  style: widget.chipStyling.textStyle?.copyWith(
                    color: isSelected 
                        ? widget.chipStyling.selectedTextColor
                        : widget.chipStyling.unselectedTextColor,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: widget.enabled && item.enabled ? (selected) {
              _toggleSelection(item.value);
            } : null,
            backgroundColor: widget.chipStyling.unselectedColor,
            selectedColor: widget.chipStyling.selectedColor ?? 
                         Theme.of(context).primaryColor.withOpacity(0.2),
            checkmarkColor: widget.chipStyling.selectedTextColor,
            showCheckmark: widget.chipStyling.showCheckmark,
            elevation: widget.chipStyling.elevation,
            padding: widget.chipStyling.padding,
            shape: widget.chipStyling.borderRadius != null
                ? RoundedRectangleBorder(
                    borderRadius: widget.chipStyling.borderRadius!,
                  )
                : null,
            tooltip: item.description,
          ),
        );
      },
    );
  }
  
  Widget _buildValidationMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            size: 16,
            color: Colors.red[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationMessage,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          return item.label.toLowerCase().contains(query) ||
                 (item.description?.toLowerCase().contains(query) ?? false) ||
                 (item.category?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }
  
  void _toggleSelection(T value) {
    if (!widget.enabled) return;
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
        _chipControllers[value]?.reverse();
      } else {
        // Check selection limits
        if (widget.selectionLimit?.maxSelections != null &&
            _selectedValues.length >= widget.selectionLimit!.maxSelections!) {
          _validationMessage = widget.selectionLimit!.getValidationMessage(_selectedValues.length + 1) ?? '';
          return;
        }
        
        _selectedValues.add(value);
        _chipControllers[value]?.forward();
      }
      
      // Update validation
      _validationMessage = widget.selectionLimit?.getValidationMessage(_selectedValues.length) ?? '';
    });
    
    widget.onSelectionChanged?.call(_selectedValues);
  }
  
  void _selectAll() {
    if (!widget.enabled) return;
    
    setState(() {
      final availableItems = _filteredItems.where((item) => item.enabled).toList();
      
      if (widget.selectionLimit?.maxSelections != null) {
        final maxItems = availableItems.take(widget.selectionLimit!.maxSelections!);
        _selectedValues = maxItems.map((item) => item.value).toList();
      } else {
        _selectedValues = availableItems.map((item) => item.value).toList();
      }
      
      _updateChipAnimations();
      _validationMessage = widget.selectionLimit?.getValidationMessage(_selectedValues.length) ?? '';
    });
    
    widget.onSelectionChanged?.call(_selectedValues);
  }
  
  void _clearAll() {
    if (!widget.enabled) return;
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _selectedValues.clear();
      for (final controller in _chipControllers.values) {
        controller.reverse();
      }
      _validationMessage = widget.selectionLimit?.getValidationMessage(0) ?? '';
    });
    
    widget.onSelectionChanged?.call(_selectedValues);
  }
  
  void _updateChipAnimations() {
    for (final entry in _chipControllers.entries) {
      if (_selectedValues.contains(entry.key)) {
        entry.value.forward();
      } else {
        entry.value.reverse();
      }
    }
  }
}

/// Reorderable wrap widget for selected items
class ReorderableWrap extends StatefulWidget {
  final List<Widget> children;
  final Function(int, int) onReorder;
  final double spacing;
  final double runSpacing;
  
  const ReorderableWrap({
    super.key,
    required this.children,
    required this.onReorder,
    this.spacing = 8.0,
    this.runSpacing = 4.0,
  });
  
  @override
  State<ReorderableWrap> createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      onReorder: widget.onReorder,
      buildDefaultDragHandles: false,
      children: widget.children,
    );
  }
}

/// Extension methods for easy MultiChoiceField creation
extension MultiChoiceFieldExtensions<T> on MultiChoiceField<T> {
  /// Create a simple multi-choice field
  static MultiChoiceField<T> simple<T>({
    required List<ChoiceItem<T>> items,
    required List<T> selectedValues,
    required ValueChanged<List<T>> onChanged,
    String? label,
  }) {
    return MultiChoiceField<T>(
      items: items,
      selectedValues: selectedValues,
      onSelectionChanged: onChanged,
      label: label,
    );
  }
  
  /// Create a searchable multi-choice field
  static MultiChoiceField<T> searchable<T>({
    required List<ChoiceItem<T>> items,
    required List<T> selectedValues,
    required ValueChanged<List<T>> onChanged,
    String? label,
    String? searchHint,
  }) {
    return MultiChoiceField<T>(
      items: items,
      selectedValues: selectedValues,
      onSelectionChanged: onChanged,
      label: label,
      searchable: true,
      searchHint: searchHint,
      showSelectAll: true,
      showClearAll: true,
    );
  }
  
  /// Create a limited selection field
  static MultiChoiceField<T> limited<T>({
    required List<ChoiceItem<T>> items,
    required List<T> selectedValues,
    required ValueChanged<List<T>> onChanged,
    required int maxSelections,
    String? label,
  }) {
    return MultiChoiceField<T>(
      items: items,
      selectedValues: selectedValues,
      onSelectionChanged: onChanged,
      label: label,
      selectionLimit: SelectionLimit(maxSelections: maxSelections),
    );
  }
  
  /// Create a categorized multi-choice field
  static MultiChoiceField<T> categorized<T>({
    required List<ChoiceItem<T>> items,
    required List<T> selectedValues,
    required ValueChanged<List<T>> onChanged,
    String? label,
  }) {
    return MultiChoiceField<T>(
      items: items,
      selectedValues: selectedValues,
      onSelectionChanged: onChanged,
      label: label,
      groupByCategory: true,
      searchable: true,
    );
  }
}

/// Predefined multi-choice configurations
class MultiChoicePresets {
  /// Sports selection field
  static MultiChoiceField<String> sports({
    required List<String> selectedSports,
    required ValueChanged<List<String>> onChanged,
    String label = 'Select Sports',
    int? maxSelections,
  }) {
    final sportsItems = [
      const ChoiceItem(value: 'tennis', label: 'Tennis', icon: Icons.sports_tennis, category: 'Racket Sports'),
      const ChoiceItem(value: 'basketball', label: 'Basketball', icon: Icons.sports_basketball, category: 'Team Sports'),
      const ChoiceItem(value: 'soccer', label: 'Soccer', icon: Icons.sports_soccer, category: 'Team Sports'),
      const ChoiceItem(value: 'badminton', label: 'Badminton', icon: Icons.sports_tennis, category: 'Racket Sports'),
      const ChoiceItem(value: 'swimming', label: 'Swimming', icon: Icons.pool, category: 'Individual Sports'),
      const ChoiceItem(value: 'running', label: 'Running', icon: Icons.directions_run, category: 'Individual Sports'),
      const ChoiceItem(value: 'cycling', label: 'Cycling', icon: Icons.pedal_bike, category: 'Individual Sports'),
      const ChoiceItem(value: 'volleyball', label: 'Volleyball', icon: Icons.sports_volleyball, category: 'Team Sports'),
    ];
    
    return MultiChoiceField<String>(
      items: sportsItems,
      selectedValues: selectedSports,
      onSelectionChanged: onChanged,
      label: label,
      searchable: true,
      groupByCategory: true,
      showSelectAll: true,
      showClearAll: true,
      selectionLimit: maxSelections != null 
          ? SelectionLimit(maxSelections: maxSelections)
          : null,
    );
  }
  
  /// Skill level selection
  static MultiChoiceField<String> skillLevels({
    required List<String> selectedLevels,
    required ValueChanged<List<String>> onChanged,
    String label = 'Skill Levels',
  }) {
    final levelItems = [
      const ChoiceItem(value: 'beginner', label: 'Beginner', color: Colors.green),
      const ChoiceItem(value: 'intermediate', label: 'Intermediate', color: Colors.orange),
      const ChoiceItem(value: 'advanced', label: 'Advanced', color: Colors.red),
      const ChoiceItem(value: 'expert', label: 'Expert', color: Colors.purple),
    ];
    
    return MultiChoiceField<String>(
      items: levelItems,
      selectedValues: selectedLevels,
      onSelectionChanged: onChanged,
      label: label,
      chipStyling: const ChipStyling(
        showCheckmark: false,
        elevation: 1,
      ),
    );
  }
  
  /// Availability selection
  static MultiChoiceField<String> availability({
    required List<String> selectedDays,
    required ValueChanged<List<String>> onChanged,
    String label = 'Available Days',
  }) {
    final dayItems = [
      const ChoiceItem(value: 'monday', label: 'Mon'),
      const ChoiceItem(value: 'tuesday', label: 'Tue'),
      const ChoiceItem(value: 'wednesday', label: 'Wed'),
      const ChoiceItem(value: 'thursday', label: 'Thu'),
      const ChoiceItem(value: 'friday', label: 'Fri'),
      const ChoiceItem(value: 'saturday', label: 'Sat'),
      const ChoiceItem(value: 'sunday', label: 'Sun'),
    ];
    
    return MultiChoiceField<String>(
      items: dayItems,
      selectedValues: selectedDays,
      onSelectionChanged: onChanged,
      label: label,
      showSelectAll: true,
      showClearAll: true,
      chipStyling: const ChipStyling(
        spacing: 4,
        runSpacing: 4,
      ),
    );
  }
}
