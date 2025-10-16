import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../themes/design_system.dart';
import '../../themes/app_theme.dart';
import '../../features/venues/presentation/screens/venue_detail_screen.dart';
import 'explore_screen.dart';

class VenueListScreen extends StatefulWidget {
  final String sport;
  final Color sportColor;

  const VenueListScreen({
    super.key,
    required this.sport,
    required this.sportColor,
  });

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      // Use the same mock data as ExploreScreen
      final allVenues = _getDemoVenues();
      setState(() {
        _venues = allVenues
            .where((venue) {
              final sports = venue['sports'] as List<dynamic>;
              return sports.contains(widget.sport);
            })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                  ? _buildErrorState()
                  : _buildVenueList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = _getFiltersForSport();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.sport} Venues',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getSportDescription(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filter) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: filter != filters.last ? 8 : 0,
                  ),
                  child: _buildFilterChip(filter['label'] ?? '', filter['value'] ?? ''),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getFiltersForSport() {
    // You can expand this for more advanced filtering
    return [
      {'label': 'All', 'value': 'All'},
      {'label': 'Open Now', 'value': 'open'},
      {'label': 'Top Rated', 'value': 'top'},
      {'label': 'Nearby', 'value': 'nearby'},
    ];
  }

  String _getSportDescription() {
    switch (widget.sport.toLowerCase()) {
      case 'football':
        return 'Find football venues and book your next game';
      case 'cricket':
        return 'Discover cricket stadiums and practice fields';
      case 'padel':
        return 'Book padel courts and find clubs';
      default:
        return 'Find and book sports venues';
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? widget.sportColor
              : context.violetWidgetBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? widget.sportColor
                : context.colors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white
                : context.colors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildVenueList() {
    final filteredVenues = _getFilteredVenues();
    if (filteredVenues.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredVenues.length,
      itemBuilder: (context, index) {
        final venue = filteredVenues[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: VenueCard(
            venue: venue,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VenueDetailScreen(venueId: venue['id'] ?? ''),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredVenues() {
    if (_selectedFilter == 'All') return _venues;
    if (_selectedFilter == 'open') {
      return _venues.where((v) => v['isOpen'] == true).toList();
    }
    if (_selectedFilter == 'top') {
      return List<Map<String, dynamic>>.from(_venues)
        ..sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
    }
    if (_selectedFilter == 'nearby') {
      return List<Map<String, dynamic>>.from(_venues)
        ..sort((a, b) => (a['distance'] as String).compareTo(b['distance'] as String));
    }
    return _venues;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.sportColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                LucideIcons.mapPin,
                size: 48,
                color: widget.sportColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No venues found',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or check back later for new venues',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DS.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                LucideIcons.wifiOff,
                size: 48,
                color: DS.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load venues',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Check your connection and try again',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVenues,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
              style: DS.primaryButton,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDemoVenues() {
    // Copy the mock venues from ExploreScreen for consistency
    return [
      {
        'name': 'Al Wasl Sports Club',
        'location': 'Al Jaddaf, Dubai',
        'sports': ['Football', 'Padel'],
        'images': ['https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'],
        'rating': 4.8,
        'isOpen': true,
        'slots': [
          {'time': '18:00', 'available': true, 'isSoon': true},
          {'time': '20:00', 'available': true, 'isSoon': false},
        ],
        'reviews': [{}, {}, {}],
        'distance': '2.1 km',
      },
      {
        'name': 'Padel Pro UAE',
        'location': 'Al Quoz, Dubai',
        'sports': ['Padel'],
        'images': ['https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=400'],
        'rating': 4.7,
        'isOpen': true,
        'slots': [
          {'time': '19:00', 'available': true, 'isSoon': true},
        ],
        'reviews': [{}, {}, {}, {}],
        'distance': '3.4 km',
      },
      {
        'name': 'Dubai Tennis Stadium',
        'location': 'Garhoud, Dubai',
        'sports': ['Padel', 'Tennis'],
        'images': ['https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400'],
        'rating': 4.9,
        'isOpen': true,
        'slots': [],
        'reviews': [{}, {}, {}],
        'distance': '5.0 km',
      },
      {
        'name': 'Sharjah Cricket Stadium',
        'location': 'Sharjah, UAE',
        'sports': ['Cricket'],
        'images': ['https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=400'],
        'rating': 4.5,
        'isOpen': false,
        'slots': [],
        'reviews': [{}, {}, {}, {}, {}],
        'distance': '18 km',
      },
      {
        'name': 'Mushrif Park Field',
        'location': 'Mushrif, Dubai',
        'sports': ['Football'],
        'images': ['https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'],
        'rating': 4.2,
        'isOpen': true,
        'slots': [
          {'time': '10:00', 'available': true, 'isSoon': false},
          {'time': '12:00', 'available': true, 'isSoon': false},
        ],
        'reviews': [{}, {}, {}, {}, {}, {}],
        'distance': '1.5 km',
      },
      {
        'name': 'Padel Point',
        'location': 'Jumeirah, Dubai',
        'sports': ['Padel'],
        'images': ['https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=400'],
        'rating': 4.8,
        'isOpen': true,
        'slots': [
          {'time': '11:00', 'available': true, 'isSoon': true},
          {'time': '13:00', 'available': true, 'isSoon': false},
        ],
        'reviews': [{}, {}, {}, {}, {}, {}, {}],
        'distance': '2.8 km',
      },
      {
        'name': 'Dubai International Cricket Stadium',
        'location': 'Sports City, Dubai',
        'sports': ['Cricket'],
        'images': ['https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=400'],
        'rating': 4.6,
        'isOpen': true,
        'slots': [
          {'time': '14:00', 'available': true, 'isSoon': false},
          {'time': '16:00', 'available': true, 'isSoon': false},
        ],
        'reviews': [{}, {}, {}, {}, {}, {}, {}, {}],
        'distance': '10 km',
      },
      {
        'name': 'Al Nasr Basketball Arena',
        'location': 'Oud Metha, Dubai',
        'sports': ['Basketball'],
        'images': ['https://images.unsplash.com/photo-1546519638-68e109498ffc?w=400'],
        'rating': 4.4,
        'isOpen': true,
        'slots': [
          {'time': '09:00', 'available': true, 'isSoon': false},
          {'time': '11:00', 'available': true, 'isSoon': false},
        ],
        'reviews': [{}, {}, {}, {}, {}, {}, {}, {}, {}],
        'distance': '1.2 km',
      },
    ];
  }
}
