import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VenuesListScreen extends ConsumerStatefulWidget {
  const VenuesListScreen({super.key});

  @override
  ConsumerState<VenuesListScreen> createState() => _VenuesListScreenState();
}

class _VenuesListScreenState extends ConsumerState<VenuesListScreen> {
  bool _isGridView = true;
  String _sortBy = 'distance'; // distance, rating, name, price
  final _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _venues = [
    {
      'id': '1',
      'name': 'Central Park Basketball Court',
      'address': '123 Main St, New York, NY',
      'distance': 1.2,
      'rating': 4.5,
      'reviewCount': 128,
      'priceRange': 'Free',
      'sports': ['Basketball', 'Tennis'],
      'amenities': ['Parking', 'Restrooms', 'Water'],
      'imageUrl': null,
      'isOpen': true,
      'openUntil': '10:00 PM',
    },
    {
      'id': '2',
      'name': 'Downtown Sports Complex',
      'address': '456 Oak Ave, New York, NY',
      'distance': 2.8,
      'rating': 4.8,
      'reviewCount': 95,
      'priceRange': '\$15-25/hr',
      'sports': ['Soccer', 'Basketball', 'Volleyball'],
      'amenities': ['Parking', 'Locker Rooms', 'Snack Bar', 'WiFi'],
      'imageUrl': null,
      'isOpen': true,
      'openUntil': '11:00 PM',
    },
    {
      'id': '3',
      'name': 'Riverside Tennis Club',
      'address': '789 River Rd, New York, NY',
      'distance': 3.5,
      'rating': 4.2,
      'reviewCount': 67,
      'priceRange': '\$20-30/hr',
      'sports': ['Tennis'],
      'amenities': ['Pro Shop', 'Parking', 'Restaurant'],
      'imageUrl': null,
      'isOpen': false,
      'openUntil': 'Closed',
    },
    {
      'id': '4',
      'name': 'Community Recreation Center',
      'address': '321 Park Blvd, New York, NY',
      'distance': 4.1,
      'rating': 4.0,
      'reviewCount': 203,
      'priceRange': '\$5-15/hr',
      'sports': ['Basketball', 'Volleyball', 'Table Tennis'],
      'amenities': ['Parking', 'Restrooms', 'Gym'],
      'imageUrl': null,
      'isOpen': true,
      'openUntil': '9:00 PM',
    },
  ];

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
          _buildSearchAndFilters(),
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Venues'),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          tooltip: _isGridView ? 'List View' : 'Grid View',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              _sortBy = value;
            });
            _applySorting(value);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'distance',
              child: Row(
                children: [
                  if (_sortBy == 'distance') const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  const Text('Sort by Distance'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'rating',
              child: Row(
                children: [
                  if (_sortBy == 'rating') const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  const Text('Sort by Rating'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'name',
              child: Row(
                children: [
                  if (_sortBy == 'name') const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  const Text('Sort by Name'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'price',
              child: Row(
                children: [
                  if (_sortBy == 'price') const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  const Text('Sort by Price'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search venues...',
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
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Basketball'),
                  selected: false,
                  onSelected: (selected) => _filterBySport('Basketball', selected),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Tennis'),
                  selected: false,
                  onSelected: (selected) => _filterBySport('Tennis', selected),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Soccer'),
                  selected: false,
                  onSelected: (selected) => _filterBySport('Soccer', selected),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Free Only'),
                  selected: false,
                  onSelected: (selected) => _filterByPrice(selected),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Open Now'),
                  selected: false,
                  onSelected: (selected) => _filterByOpenStatus(selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return RefreshIndicator(
      onRefresh: _refreshVenues,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _venues.length,
        itemBuilder: (context, index) {
          final venue = _venues[index];
          return _buildVenueGridCard(venue);
        },
      ),
    );
  }

  Widget _buildVenueGridCard(Map<String, dynamic> venue) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToVenueDetail(venue['id']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.grey[300],
                child: venue['imageUrl'] != null
                    ? Image.network(venue['imageUrl'], fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      venue['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Rating and Distance
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          venue['rating'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${venue['distance']} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Price
                    Text(
                      venue['priceRange'],
                      style: TextStyle(
                        fontSize: 12,
                        color: venue['priceRange'] == 'Free' 
                            ? Colors.green[600] 
                            : Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Open Status
                    if (venue['isOpen'])
                      Text(
                        'Open until ${venue['openUntil']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[600],
                        ),
                      )
                    else
                      Text(
                        'Closed',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[600],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _refreshVenues,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _venues.length,
        itemBuilder: (context, index) {
          final venue = _venues[index];
          return _buildVenueListCard(venue);
        },
      ),
    );
  }

  Widget _buildVenueListCard(Map<String, dynamic> venue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToVenueDetail(venue['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: venue['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(venue['imageUrl'], fit: BoxFit.cover),
                      )
                    : const Icon(Icons.image, size: 30, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            venue['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: venue['isOpen'] ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            venue['isOpen'] ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: venue['isOpen'] ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Address
                    Text(
                      venue['address'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Rating, Distance, Price
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${venue['rating']} (${venue['reviewCount']})',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${venue['distance']} km',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          venue['priceRange'],
                          style: TextStyle(
                            fontSize: 14,
                            color: venue['priceRange'] == 'Free' 
                                ? Colors.green[600] 
                                : Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Sports Tags
                    Wrap(
                      spacing: 4,
                      children: (venue['sports'] as List<String>)
                          .take(3)
                          .map((sport) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sport,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    
                    if (venue['isOpen'])
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Open until ${venue['openUntil']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Action Button
              Column(
                children: [
                  IconButton(
                    onPressed: () => _bookVenue(venue['id']),
                    icon: const Icon(Icons.book_online),
                    color: Colors.blue,
                    tooltip: 'Book Now',
                  ),
                  IconButton(
                    onPressed: () => _getDirections(venue),
                    icon: const Icon(Icons.directions),
                    color: Colors.green,
                    tooltip: 'Directions',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    print('Searching venues: $query');
  }

  void _applySorting(String sortBy) {
    setState(() {
      switch (sortBy) {
        case 'distance':
          _venues.sort((a, b) => a['distance'].compareTo(b['distance']));
          break;
        case 'rating':
          _venues.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        case 'name':
          _venues.sort((a, b) => a['name'].compareTo(b['name']));
          break;
        case 'price':
          // Custom price sorting logic
          break;
      }
    });
  }

  void _filterBySport(String sport, bool selected) {
    print('Filter by sport: $sport, selected: $selected');
  }

  void _filterByPrice(bool freeOnly) {
    print('Filter free only: $freeOnly');
  }

  void _filterByOpenStatus(bool openOnly) {
    print('Filter open only: $openOnly');
  }

  Future<void> _refreshVenues() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void _navigateToVenueDetail(String venueId) {
    Navigator.pushNamed(
      context,
      '/venues/detail',
      arguments: venueId,
    );
  }

  void _bookVenue(String venueId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking venue $venueId...')),
    );
  }

  void _getDirections(Map<String, dynamic> venue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening directions to ${venue['name']}')),
    );
  }
}
