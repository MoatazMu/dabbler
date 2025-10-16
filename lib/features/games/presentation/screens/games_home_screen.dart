import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/games_providers.dart';

class GamesHomeScreen extends ConsumerStatefulWidget {
  const GamesHomeScreen({super.key});

  @override
  ConsumerState<GamesHomeScreen> createState() => _GamesHomeScreenState();
}

class _GamesHomeScreenState extends ConsumerState<GamesHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _hasLocationPermission = false;
  bool _isRequestingLocation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkLocationPermission();
    
    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    // Simplified - check if Geolocator permissions are enabled
    LocationPermission permission = await Geolocator.checkPermission();
    setState(() {
      _hasLocationPermission = permission == LocationPermission.always || 
                                permission == LocationPermission.whileInUse;
    });
  }

  Future<void> _requestLocationPermission() async {
    if (_isRequestingLocation) return;
    
    setState(() {
      _isRequestingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        await ref.read(gamesActionsProvider).setUserLocation(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _hasLocationPermission = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRequestingLocation = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    if (_hasLocationPermission) {
      try {
        final position = await Geolocator.getCurrentPosition();
        await ref.read(gamesActionsProvider).setUserLocation(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        // Handle silently, user can still browse without location
      }
    }
    
    await ref.read(gamesActionsProvider).loadGames();
  }

  Future<void> _onRefresh() async {
    await ref.read(gamesActionsProvider).refreshGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildMyGamesTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Dabbler',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Discover', icon: Icon(Icons.explore)),
          Tab(text: 'My Games', icon: Icon(Icons.sports_basketball)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            // Navigate to profile
          },
        ),
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: _buildSearchSection(),
          ),
          
          // Location Permission Banner
          if (!_hasLocationPermission)
            SliverToBoxAdapter(
              child: _buildLocationPermissionBanner(),
            ),
          
          // Filter Chips
          SliverToBoxAdapter(
            child: _buildFilterChipsSection(),
          ),
          
          // Nearby Games Section
          if (_hasLocationPermission)
            SliverToBoxAdapter(
              child: _buildNearbyGamesSection(),
            ),
          
          // Upcoming Games This Week
          SliverToBoxAdapter(
            child: _buildSectionHeader('Upcoming This Week'),
          ),
          
          _buildUpcomingGamesList(),
        ],
      ),
    );
  }

  Widget _buildMyGamesTab() {
    // Placeholder for MyGamesScreen
    return const Center(
      child: Text('My Games Tab - To be implemented'),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search games, sports, or venues...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // Clear search results
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          // Debounced search implementation
          _debounceSearch(value);
        },
      ),
    );
  }

  void _debounceSearch(String query) {
    // Simple debouncing - in production, use a proper debouncing library
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query && query.isNotEmpty) {
        // Perform search
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    // Update filters with search query
    final currentFilters = ref.read(currentFiltersProvider);
    // In a real implementation, you'd add search to filters
    ref.read(gamesActionsProvider).updateFilters(currentFilters);
  }

  Widget _buildLocationPermissionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find games near you',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable location to discover nearby games and venues',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isRequestingLocation ? null : _requestLocationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isRequestingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsSection() {
    return Consumer(
      builder: (context, ref, child) {
        // Placeholder for FilterChipsSection
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text('Filter Chips - To be implemented'),
        );
      },
    );
  }

  Widget _buildNearbyGamesSection() {
    return Consumer(
      builder: (context, ref, child) {
        final nearbyGames = ref.watch(nearbyGamesProvider);
        final isLoading = ref.watch(gamesLoadingProvider);

        if (isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (nearbyGames.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.location_searching, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No nearby games', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Try expanding your search radius or check back later'),
                  ],
                ),
              ),
            ),
          );
        }

        // Placeholder for NearbyGamesSection
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: nearbyGames.length,
            itemBuilder: (context, index) {
              final game = nearbyGames[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${game.sport} • ${game.startTime}'),
                        Text('${game.currentPlayers}/${game.maxPlayers} players'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to see all games
              Navigator.pushNamed(context, '/games/all');
            },
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingGamesList() {
    return Consumer(
      builder: (context, ref, child) {
        final upcomingGames = ref.watch(upcomingGamesProvider);
        final isLoading = ref.watch(gamesLoadingProvider);
        final gamesState = ref.watch(gamesControllerProvider);

        if (isLoading && upcomingGames.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (upcomingGames.isEmpty && !isLoading) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No upcoming games', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Be the first to create a game in your area!'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (gamesState.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load games',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gamesState.error ?? 'Unknown error occurred',
                        style: TextStyle(color: Colors.red[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(gamesActionsProvider).refreshGames(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == upcomingGames.length) {
                // Load more button or automatic pagination
                return _buildLoadMoreButton();
              }
              
              final game = upcomingGames[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(game.sport.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(game.title),
                    subtitle: Text('${game.startTime} • ${game.currentPlayers}/${game.maxPlayers} players'),
                    trailing: Text('\$${game.pricePerPlayer.toStringAsFixed(0)}'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/games/detail',
                        arguments: game.id,
                      );
                    },
                  ),
                ),
              );
            },
            childCount: upcomingGames.length + 1,
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Consumer(
      builder: (context, ref, child) {
        final gamesState = ref.watch(gamesControllerProvider);
        final pagination = gamesState.paginationInfo;
        
        if (pagination?.hasNextPage != true) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ElevatedButton(
              onPressed: () => ref.read(gamesActionsProvider).loadMore(),
              child: const Text('Load More Games'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Navigate to create game screen (placeholder)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create Game screen - To be implemented')),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Create Game'),
      backgroundColor: Colors.blue[600],
    );
  }
}
