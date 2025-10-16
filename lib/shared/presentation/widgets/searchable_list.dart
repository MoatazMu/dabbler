import 'package:flutter/material.dart';
import 'dart:async';

/// Searchable list widget with debounced search, suggestions, and recent searches
class SearchableList<T> extends StatefulWidget {
  /// All items to search through
  final List<T> allItems;
  
  /// Function to build each list item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  
  /// Function to extract searchable text from item
  final String Function(T item) searchTextExtractor;
  
  /// Function called when search query changes
  final Function(String query)? onSearchChanged;
  
  /// Placeholder text for search bar
  final String searchHint;
  
  /// Whether to show search suggestions
  final bool showSuggestions;
  
  /// Search suggestions
  final List<String> suggestions;
  
  /// Function called when suggestion is tapped
  final Function(String suggestion)? onSuggestionTapped;
  
  /// Whether to show recent searches
  final bool showRecentSearches;
  
  /// Recent search queries
  final List<String> recentSearches;
  
  /// Function called when recent search is tapped
  final Function(String recentSearch)? onRecentSearchTapped;
  
  /// Function called to clear recent searches
  final VoidCallback? onClearRecentSearches;
  
  /// Widget to show when no search results
  final Widget? noResultsWidget;
  
  /// Widget to show when search is empty
  final Widget? emptySearchWidget;
  
  /// Debounce duration for search
  final Duration debounceDuration;
  
  /// Minimum characters to trigger search
  final int minSearchLength;
  
  /// Whether to show loading indicator during search
  final bool isSearching;
  
  /// Custom search filter function
  final bool Function(T item, String query)? customSearchFilter;

  const SearchableList({
    super.key,
    required this.allItems,
    required this.itemBuilder,
    required this.searchTextExtractor,
    this.onSearchChanged,
    this.searchHint = 'Search...',
    this.showSuggestions = false,
    this.suggestions = const [],
    this.onSuggestionTapped,
    this.showRecentSearches = false,
    this.recentSearches = const [],
    this.onRecentSearchTapped,
    this.onClearRecentSearches,
    this.noResultsWidget,
    this.emptySearchWidget,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minSearchLength = 1,
    this.isSearching = false,
    this.customSearchFilter,
  });

  @override
  State<SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<SearchableList<T>> {
  late TextEditingController _searchController;
  Timer? _debounceTimer;
  String _currentQuery = '';
  List<T> _filteredItems = [];
  bool _showSearchSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.allItems;
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allItems != oldWidget.allItems) {
      _filterItems(_currentQuery);
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;
    
    setState(() {
      _showSearchSuggestions = query.isNotEmpty && 
          (widget.showSuggestions && widget.suggestions.isNotEmpty);
    });
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      _filterItems(query);
      widget.onSearchChanged?.call(query);
    });
  }

  void _filterItems(String query) {
    setState(() {
      _currentQuery = query;
      
      if (query.length < widget.minSearchLength) {
        _filteredItems = widget.allItems;
        return;
      }

      if (widget.customSearchFilter != null) {
        _filteredItems = widget.allItems
            .where((item) => widget.customSearchFilter!(item, query))
            .toList();
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredItems = widget.allItems
            .where((item) => widget.searchTextExtractor(item)
                .toLowerCase()
                .contains(lowercaseQuery))
            .toList();
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _showSearchSuggestions = false;
    });
    _filterItems(suggestion);
    widget.onSuggestionTapped?.call(suggestion);
  }

  void _selectRecentSearch(String recentSearch) {
    _searchController.text = recentSearch;
    setState(() {
      _showSearchSuggestions = false;
    });
    _filterItems(recentSearch);
    widget.onRecentSearchTapped?.call(recentSearch);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _filteredItems = widget.allItems;
      _showSearchSuggestions = false;
    });
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _currentQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Show search suggestions
    if (_showSearchSuggestions) {
      return _buildSuggestions();
    }

    // Show recent searches when search is empty
    if (_currentQuery.isEmpty && widget.showRecentSearches && 
        widget.recentSearches.isNotEmpty) {
      return _buildRecentSearches();
    }

    // Show loading indicator
    if (widget.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show no results
    if (_filteredItems.isEmpty && _currentQuery.isNotEmpty) {
      return widget.noResultsWidget ?? _buildNoResultsWidget();
    }

    // Show empty search state
    if (_filteredItems.isEmpty && _currentQuery.isEmpty) {
      return widget.emptySearchWidget ?? _buildEmptySearchWidget();
    }

    // Show filtered results
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return widget.itemBuilder(context, _filteredItems[index], index);
      },
    );
  }

  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    
    return ListView.builder(
      itemCount: widget.suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = widget.suggestions[index];
        return ListTile(
          leading: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(suggestion),
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.onClearRecentSearches != null)
                TextButton(
                  onPressed: widget.onClearRecentSearches,
                  child: const Text('Clear All'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.recentSearches.length,
            itemBuilder: (context, index) {
              final recentSearch = widget.recentSearches[index];
              return ListTile(
                leading: Icon(
                  Icons.history_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(recentSearch),
                trailing: IconButton(
                  onPressed: () => _selectRecentSearch(recentSearch),
                  icon: const Icon(Icons.north_west_rounded),
                ),
                onTap: () => _selectRecentSearch(recentSearch),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsWidget() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchWidget() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Start searching',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter keywords to find what you\'re looking for',
              style: theme.textTheme.bodyMedium?.copyWith(
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

/// Search bar widget that can be used separately
class CustomSearchBar extends StatefulWidget {
  final String? initialQuery;
  final String hintText;
  final Function(String query)? onChanged;
  final VoidCallback? onClear;
  final bool isLoading;

  const CustomSearchBar({
    super.key,
    this.initialQuery,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.isLoading = false,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
