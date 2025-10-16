import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../../core/error/failures.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../data/models/search_filter_model.dart';

/// State for user search functionality
class UserSearchState {
  final String query;
  final List<UserProfile> searchResults;
  final List<String> recentSearches;
  final List<String> searchSuggestions;
  final Map<String, List<UserProfile>> searchCache;
  final bool isSearching;
  final bool isLoadingSuggestions;
  final String? error;
  final SearchFilterModel filters;
  final bool hasMore;
  final int currentPage;
  final Map<String, DateTime> cacheTimestamps;

  const UserSearchState({
    this.query = '',
    this.searchResults = const [],
    this.recentSearches = const [],
    this.searchSuggestions = const [],
    this.searchCache = const {},
    this.isSearching = false,
    this.isLoadingSuggestions = false,
    this.error,
    this.filters = const SearchFilterModel(),
    this.hasMore = false,
    this.currentPage = 1,
    this.cacheTimestamps = const {},
  });

  UserSearchState copyWith({
    String? query,
    List<UserProfile>? searchResults,
    List<String>? recentSearches,
    List<String>? searchSuggestions,
    Map<String, List<UserProfile>>? searchCache,
    bool? isSearching,
    bool? isLoadingSuggestions,
    String? error,
    SearchFilterModel? filters,
    bool? hasMore,
    int? currentPage,
    Map<String, DateTime>? cacheTimestamps,
  }) {
    return UserSearchState(
      query: query ?? this.query,
      searchResults: searchResults ?? this.searchResults,
      recentSearches: recentSearches ?? this.recentSearches,
      searchSuggestions: searchSuggestions ?? this.searchSuggestions,
      searchCache: searchCache ?? this.searchCache,
      isSearching: isSearching ?? this.isSearching,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      error: error,
      filters: filters ?? this.filters,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      cacheTimestamps: cacheTimestamps ?? this.cacheTimestamps,
    );
  }

  // Computed getters
  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => searchResults.isNotEmpty;
  bool get hasRecentSearches => recentSearches.isNotEmpty;
  bool get hasSuggestions => searchSuggestions.isNotEmpty;
  bool get hasActiveFilters => filters.hasActiveFilters;
  bool get canLoadMore => hasMore && !isSearching;
}

/// Controller for user search functionality
class UserSearchController extends StateNotifier<UserSearchState> {
  final SearchUsersUseCase _searchUsersUseCase;
  
  Timer? _debounceTimer;
  Timer? _suggestionsTimer;
  StreamSubscription? _searchHistorySubscription;
  
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const Duration _cacheExpiry = Duration(minutes: 10);

  UserSearchController(this._searchUsersUseCase) : super(const UserSearchState()) {
    _loadRecentSearches();
    _loadSearchSuggestions();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionsTimer?.cancel();
    _searchHistorySubscription?.cancel();
    super.dispose();
  }

  /// Update search query with debouncing
  void updateQuery(String query) {
    state = state.copyWith(
      query: query,
      error: null,
    );

    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      // Clear results for empty query
      state = state.copyWith(
        searchResults: [],
        hasMore: false,
        currentPage: 1,
      );
      _loadSearchSuggestions();
      return;
    }

    // Check cache first
    final cacheKey = _generateCacheKey(query, state.filters);
    final cachedResults = _getCachedResults(cacheKey);
    
    if (cachedResults != null) {
      state = state.copyWith(
        searchResults: cachedResults,
        hasMore: cachedResults.length >= 20, // Assume more if we got full page
        currentPage: 1,
      );
      return;
    }

    // Debounce the search
    _debounceTimer = Timer(_debounceDelay, () {
      if (state.query == query) {
        _performSearch(query, refresh: true);
      }
    });
  }

  /// Perform search with current query and filters
  Future<void> searchUsers({bool loadMore = false}) async {
    if (state.query.trim().isEmpty) return;
    
    if (loadMore) {
      await _performSearch(state.query, page: state.currentPage + 1);
    } else {
      await _performSearch(state.query, refresh: true);
    }
  }

  /// Update search filters
  Future<void> updateFilters(SearchFilterModel newFilters) async {
    state = state.copyWith(
      filters: newFilters,
      currentPage: 1,
    );

    // Re-search with new filters if there's a query
    if (state.hasQuery) {
      await _performSearch(state.query, refresh: true);
    }
  }

  /// Clear specific filter
  Future<void> clearFilter(SearchFilterType filterType) async {
    SearchFilterModel updatedFilters;
    
    switch (filterType) {
      case SearchFilterType.sport:
        updatedFilters = state.filters.copyWith(sportsCategories: []);
        break;
      case SearchFilterType.location:
        updatedFilters = state.filters.copyWith(
          location: null,
          radius: null,
        );
        break;
      case SearchFilterType.skillLevel:
        updatedFilters = state.filters.copyWith(skillLevels: []);
        break;
      case SearchFilterType.age:
        updatedFilters = state.filters.copyWith(
          minAge: null,
          maxAge: null,
        );
        break;
      case SearchFilterType.gender:
        updatedFilters = state.filters.copyWith(gender: null);
        break;
    }

    await updateFilters(updatedFilters);
  }

  /// Clear all filters
  Future<void> clearAllFilters() async {
    await updateFilters(const SearchFilterModel());
  }

  /// Add query to recent searches
  void _addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;

    final updatedRecent = [query, ...state.recentSearches]
        .where((search) => search != query) // Remove duplicates
        .take(10) // Keep only 10 recent searches
        .toList();

    state = state.copyWith(recentSearches: updatedRecent);
    
    // Persist recent searches
    _persistRecentSearches(updatedRecent);
  }

  /// Select from recent searches
  void selectRecentSearch(String query) {
    updateQuery(query);
  }

  /// Clear recent searches
  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
    _persistRecentSearches([]);
  }

  /// Load more search results (pagination)
  Future<void> loadMoreResults() async {
    if (!state.canLoadMore) return;
    
    await searchUsers(loadMore: true);
  }

  /// Refresh current search
  Future<void> refreshSearch() async {
    if (!state.hasQuery) return;
    
    await _performSearch(state.query, refresh: true);
  }

  /// Get search suggestions based on input
  Future<void> loadSearchSuggestions([String? query]) async {
    final searchQuery = query ?? state.query;
    
    if (searchQuery.isEmpty) {
      _loadPopularSuggestions();
      return;
    }

    state = state.copyWith(isLoadingSuggestions: true);

    try {
      final suggestions = await _fetchSearchSuggestions(searchQuery);
      
      // Only update if query hasn't changed
      if (state.query == searchQuery) {
        state = state.copyWith(
          searchSuggestions: suggestions,
          isLoadingSuggestions: false,
        );
      }
    } catch (e) {
      if (state.query == searchQuery) {
        state = state.copyWith(
          isLoadingSuggestions: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Clear search results and query
  void clearSearch() {
    state = state.copyWith(
      query: '',
      searchResults: [],
      hasMore: false,
      currentPage: 1,
      error: null,
    );
    
    _loadSearchSuggestions();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear search cache
  void clearCache() {
    state = state.copyWith(
      searchCache: {},
      cacheTimestamps: {},
    );
  }

  /// Get cached results if available and not expired

  List<UserProfile>? _getCachedResults(String cacheKey) {
    final cached = state.searchCache[cacheKey];
    final timestamp = state.cacheTimestamps[cacheKey];
    
    if (cached != null && timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age < _cacheExpiry) {
        return cached;
      }
    }
    
    return null;
  }

  /// Cache search results
  void _cacheResults(String cacheKey, List<UserProfile> results) {
    final updatedCache = Map<String, List<UserProfile>>.from(state.searchCache);
    final updatedTimestamps = Map<String, DateTime>.from(state.cacheTimestamps);
    
    updatedCache[cacheKey] = results;
    updatedTimestamps[cacheKey] = DateTime.now();
    
    // Limit cache size
    if (updatedCache.length > 50) {
      final oldestKey = updatedTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      
      updatedCache.remove(oldestKey);
      updatedTimestamps.remove(oldestKey);
    }

    state = state.copyWith(
      searchCache: updatedCache,
      cacheTimestamps: updatedTimestamps,
    );
  }

  /// Generate cache key for search parameters
  String _generateCacheKey(String query, SearchFilterModel filters) {
    final components = [
      query.toLowerCase(),
      filters.sportsCategories.join(','),
      filters.location?.toString() ?? '',
      filters.radius?.toString() ?? '',
      filters.skillLevels.join(','),
      filters.minAge?.toString() ?? '',
      filters.maxAge?.toString() ?? '',
      filters.gender ?? '',
    ];
    
    return components.join('_');
  }

  /// Helper to convert SearchFilterModel to Map<String, dynamic>
  Map<String, dynamic> _filtersToMap(SearchFilterModel filters) {
    return {
      'sportsCategories': filters.sportsCategories,
      'location': filters.location,
      'radius': filters.radius,
      'skillLevels': filters.skillLevels,
      'minAge': filters.minAge,
      'maxAge': filters.maxAge,
      'gender': filters.gender,
    }..removeWhere((key, value) => value == null || (value is List && value.isEmpty));
  }

  /// Perform the actual search
  Future<void> _performSearch(String query, {int page = 1, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isSearching: true,
        currentPage: 1,
        error: null,
      );
    } else {
      state = state.copyWith(isSearching: true);
    }

    try {
      final params = SearchUsersParams(
        query: query,
        filters: _filtersToMap(state.filters),
        page: page,
        limit: 20,
      );

      final result = await _searchUsersUseCase(params);
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isSearching: false,
            error: failure.message,
          );
        },
        (success) {
          final newResults = success.users;
          final allResults = refresh 
              ? newResults 
              : [...state.searchResults, ...newResults];

          // Cache the results
          final cacheKey = _generateCacheKey(query, state.filters);
          _cacheResults(cacheKey, allResults);

          // Add to recent searches
          if (refresh && query.isNotEmpty) {
            _addToRecentSearches(query);
          }

          state = state.copyWith(
            searchResults: allResults,
            isSearching: false,
            hasMore: newResults.length >= params.limit,
            currentPage: page,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
      );
    }
  }

  /// Load popular search suggestions
  Future<void> _loadPopularSuggestions() async {
    state = state.copyWith(isLoadingSuggestions: true);

    try {
      final suggestions = await _fetchPopularSuggestions();
      
      state = state.copyWith(
        searchSuggestions: suggestions,
        isLoadingSuggestions: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSuggestions: false,
        error: e.toString(),
      );
    }
  }

  /// Load search suggestions based on query
  Future<void> _loadSearchSuggestions() async {
    _suggestionsTimer?.cancel();
    _suggestionsTimer = Timer(const Duration(milliseconds: 300), () {
      loadSearchSuggestions();
    });
  }

  // Mock data fetching methods (replace with actual implementations)
  Future<void> _loadRecentSearches() async {
    // Mock loading recent searches from storage
    await Future.delayed(const Duration(milliseconds: 100));
    
    final mockRecentSearches = [
      'john', 'basketball players', 'soccer coach', 'tennis partner'
    ];
    
    state = state.copyWith(recentSearches: mockRecentSearches);
  }

  Future<List<String>> _fetchSearchSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Mock suggestions based on query
    final suggestions = [
      '${query.toLowerCase()} players',
      '${query.toLowerCase()} coach',
      '${query.toLowerCase()} team',
      '${query.toLowerCase()} partner',
      '${query.toLowerCase()} mentor',
    ].where((suggestion) => suggestion != query.toLowerCase()).take(5).toList();
    
    return suggestions;
  }

  Future<List<String>> _fetchPopularSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 150));
    
    return [
      'basketball players',
      'soccer coach', 
      'tennis partner',
      'football team',
      'running buddy',
      'gym partner',
      'yoga instructor',
    ];
  }

  Future<void> _persistRecentSearches(List<String> searches) async {
    // Mock persisting recent searches to storage
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

/// Search filter types
enum SearchFilterType {
  sport,
  location,
  skillLevel,
  age,
  gender,
}

/// Extension to check if filters are active
extension SearchFilterModelExtension on SearchFilterModel {
  bool get hasActiveFilters {
    return sportsCategories.isNotEmpty ||
           location != null ||
           skillLevels.isNotEmpty ||
           minAge != null ||
           maxAge != null ||
           gender != null;
  }
}
