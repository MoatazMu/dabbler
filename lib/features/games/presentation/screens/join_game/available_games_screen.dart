import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/games_providers.dart';

class AvailableGamesScreen extends ConsumerStatefulWidget {
  const AvailableGamesScreen({super.key});

  @override
  ConsumerState<AvailableGamesScreen> createState() => _AvailableGamesScreenState();
}

class _AvailableGamesScreenState extends ConsumerState<AvailableGamesScreen> {
  bool _isMapView = false;
  final _searchController = TextEditingController();
  String _sortBy = 'distance'; // distance, date, price
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndSort(),
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilters,
        tooltip: 'Filters',
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Available Games'),
      actions: [
        IconButton(
          icon: Icon(_isMapView ? Icons.list : Icons.map),
          onPressed: () {
            setState(() {
              _isMapView = !_isMapView;
            });
          },
          tooltip: _isMapView ? 'List View' : 'Map View',
        ),
      ],
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
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
            onChanged: _performSearch,
          ),
          const SizedBox(height: 12),
          
          // Sort Options
          Row(
            children: [
              const Text('Sort by: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'distance', child: Text('Distance')),
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                  DropdownMenuItem(value: 'players', child: Text('Players')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                    _applySorting(value);
                  }
                },
              ),
              const Spacer(),
              Text('${_getGameCount()} games found'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Consumer(
      builder: (context, ref, child) {
        final allGames = ref.watch(upcomingGamesProvider);
        final isLoading = ref.watch(gamesLoadingProvider);

        if (isLoading && allGames.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (allGames.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No games found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Try adjusting your filters or search terms'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(gamesActionsProvider).refreshGames();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allGames.length,
            itemBuilder: (context, index) {
              final game = allGames[index];
              return _buildGameCard(game);
            },
          ),
        );
      },
    );
  }

  Widget _buildGameCard(game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToGameDetail(game.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Game Sport Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getSportColor(game.sport),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getSportIcon(game.sport),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Game Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${game.sport.toUpperCase()} • ${game.skillLevel.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Price
                  if (game.pricePerPlayer > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '\$${game.pricePerPlayer.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date, Time, Location
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(game.scheduledDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${game.startTime} - ${game.endTime}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (game.venueId != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Venue: ${game.venueId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              
              // Players and Join Status
              Row(
                children: [
                  // Players Count
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          children: List.generate(
                            (game.currentPlayers > 3 ? 3 : game.currentPlayers),
                            (index) => Container(
                              margin: EdgeInsets.only(left: index * 15.0),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.blue[300],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (game.currentPlayers > 3)
                          Container(
                            margin: const EdgeInsets.only(left: 45),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '+${game.currentPlayers - 3}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '${game.currentPlayers}/${game.maxPlayers} players',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  // Join Button
                  ElevatedButton(
                    onPressed: () => _joinGame(game),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canJoinGame(game) ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _getJoinButtonText(game),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    // Placeholder for map view
    return Container(
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Map View',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Map integration - To be implemented'),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAdvancedFilters(),
    );
  }

  Widget _buildAdvancedFilters() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Date Range
                    _buildFilterSection(
                      'Date Range',
                      Icons.calendar_today,
                      [
                        ListTile(
                          title: const Text('Select Date Range'),
                          subtitle: const Text('Tap to choose start and end dates'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _showDateRangePicker(),
                        ),
                      ],
                    ),
                    
                    // Distance
                    _buildFilterSection(
                      'Distance',
                      Icons.location_on,
                      [
                        const ListTile(
                          title: Text('Radius: 10 km'),
                          subtitle: Text('Adjust search radius'),
                        ),
                      ],
                    ),
                    
                    // Sports
                    _buildFilterSection(
                      'Sports',
                      Icons.sports,
                      [
                        _buildSportChip('Basketball'),
                        _buildSportChip('Football'),
                        _buildSportChip('Tennis'),
                        _buildSportChip('Soccer'),
                      ],
                    ),
                    
                    // Skill Level
                    _buildFilterSection(
                      'Skill Level',
                      Icons.star,
                      [
                        _buildSkillChip('Beginner'),
                        _buildSkillChip('Intermediate'),
                        _buildSkillChip('Advanced'),
                        _buildSkillChip('Mixed'),
                      ],
                    ),
                    
                    // Price Range
                    _buildFilterSection(
                      'Price Range',
                      Icons.monetization_on,
                      [
                        const ListTile(
                          title: Text('Free - \$50'),
                          subtitle: Text('Adjust price range'),
                        ),
                      ],
                    ),
                    
                    // Apply Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSportChip(String sport) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilterChip(
        label: Text(sport),
        selected: false,
        onSelected: (selected) {
        },
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilterChip(
        label: Text(skill),
        selected: false,
        onSelected: (selected) {
        },
      ),
    );
  }

  void _performSearch(String query) {
    print('Searching for: $query');
  }

  void _applySorting(String sortBy) {
    print('Sorting by: $sortBy');
  }

  void _applyFilters() {
    print('Applying filters');
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      print('Date range: ${picked.start} - ${picked.end}');
    }
  }

  void _navigateToGameDetail(String gameId) {
    Navigator.pushNamed(
      context,
      '/games/detail',
      arguments: gameId,
    );
  }

  void _joinGame(game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining game: ${game.title}')),
    );
  }

  bool _canJoinGame(game) {
    return game.currentPlayers < game.maxPlayers;
  }

  String _getJoinButtonText(game) {
    if (game.currentPlayers >= game.maxPlayers) {
      return 'Full';
    }
    return 'Join';
  }

  int _getGameCount() {
    return 0;
  }

  Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Colors.orange;
      case 'football':
        return Colors.brown;
      case 'tennis':
        return Colors.green;
      case 'soccer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Icons.sports_basketball;
      case 'football':
        return Icons.sports_football;
      case 'tennis':
        return Icons.sports_tennis;
      case 'soccer':
        return Icons.sports_soccer;
      default:
        return Icons.sports;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
