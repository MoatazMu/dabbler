import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AchievementSearchBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;
  final bool hasActiveFilters;

  const AchievementSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onFilterTap,
    this.onSortTap,
    this.hasActiveFilters = false,
  });

  @override
  State<AchievementSearchBar> createState() => _AchievementSearchBarState();
}

class _AchievementSearchBarState extends State<AchievementSearchBar> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onSearchChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isExpanded 
                      ? Theme.of(context).primaryColor 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _controller,
                onTap: () => setState(() => _isExpanded = true),
                onSubmitted: (_) => setState(() => _isExpanded = false),
                decoration: InputDecoration(
                  hintText: 'Search achievements...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isExpanded 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[500],
                  ),
                  suffixIcon: widget.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          color: Colors.grey[500],
                          onPressed: () {
                            _controller.clear();
                            setState(() => _isExpanded = false);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate()
              .slideX(
                begin: -0.2,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOutCubic,
              ),
          ),
          
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.filter_list,
              onTap: widget.onFilterTap!,
              isActive: widget.hasActiveFilters,
              tooltip: 'Filter',
            ).animate()
              .fadeIn(
                duration: 200.ms,
                delay: 100.ms,
              )
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 200.ms,
                delay: 100.ms,
              ),
          ],
          
          if (widget.onSortTap != null) ...[
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.sort,
              onTap: widget.onSortTap!,
              tooltip: 'Sort',
            ).animate()
              .fadeIn(
                duration: 200.ms,
                delay: 150.ms,
              )
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 200.ms,
                delay: 150.ms,
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final String? tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).primaryColor 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: isActive 
            ? null 
            : Border.all(color: Colors.grey[300]!),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 20,
        ),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

// Expandable search bar variant
class ExpandableAchievementSearchBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;
  final bool hasActiveFilters;

  const ExpandableAchievementSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onFilterTap,
    this.onSortTap,
    this.hasActiveFilters = false,
  });

  @override
  State<ExpandableAchievementSearchBar> createState() => 
      _ExpandableAchievementSearchBarState();
}

class _ExpandableAchievementSearchBarState 
    extends State<ExpandableAchievementSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _controller = TextEditingController(text: widget.searchQuery);
    _controller.addListener(_onTextChanged);
    
    // Auto-expand if there's existing search text
    if (widget.searchQuery.isNotEmpty) {
      _isExpanded = true;
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onSearchChanged(_controller.text);
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Expanded(
                flex: (3 * _expandAnimation.value).round() + 1,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isExpanded 
                          ? Theme.of(context).primaryColor 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: _isExpanded
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search achievements...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              color: Colors.grey[500],
                              onPressed: _toggleExpanded,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Center(
                          child: IconButton(
                            icon: const Icon(Icons.search),
                            color: Colors.grey[600],
                            onPressed: _toggleExpanded,
                          ),
                        ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 12),
          
          // Filter button
          if (widget.onFilterTap != null)
            _ActionButton(
              icon: Icons.filter_list,
              onTap: widget.onFilterTap!,
              isActive: widget.hasActiveFilters,
              tooltip: 'Filter',
            ),
          
          // Sort button
          if (widget.onSortTap != null) ...[
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.sort,
              onTap: widget.onSortTap!,
              tooltip: 'Sort',
            ),
          ],
        ],
      ),
    );
  }
}

// Compact search widget for smaller spaces
class CompactSearchField extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? hintText;

  const CompactSearchField({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}