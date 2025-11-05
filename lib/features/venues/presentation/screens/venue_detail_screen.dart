import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dabbler/core/config/feature_flags.dart';
import 'package:dabbler/features/venues/providers.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;

  // Mock data as fallback (will be replaced by real data from provider)
  final Map<String, dynamic> _venueData = {
    'id': '1',
    'name': 'Central Park Basketball Court',
    'description':
        'A beautiful outdoor basketball court located in the heart of Central Park. Features professional-grade surfaces and equipment with stunning city views.',
    'address': '123 Main Street, New York, NY 10001',
    'coordinates': {'lat': 40.7831, 'lng': -73.9712},
    'phone': '+1 (555) 123-4567',
    'email': 'info@centralparkcourt.com',
    'website': 'www.centralparkcourt.com',
    'rating': 4.5,
    'reviewCount': 128,
    'priceRange': 'Free',
    'images': [
      'https://example.com/image1.jpg',
      'https://example.com/image2.jpg',
      'https://example.com/image3.jpg',
    ],
    'sports': ['Basketball', 'Tennis'],
    'amenities': [
      'Free Parking',
      'Restrooms',
      'Water Fountain',
      'Lighting',
      'Seating Area',
    ],
    'features': [
      'Outdoor Courts',
      '2 Basketball Courts',
      'Professional Grade Surface',
      'Spectator Seating',
    ],
    'hours': {
      'monday': '6:00 AM - 10:00 PM',
      'tuesday': '6:00 AM - 10:00 PM',
      'wednesday': '6:00 AM - 10:00 PM',
      'thursday': '6:00 AM - 10:00 PM',
      'friday': '6:00 AM - 11:00 PM',
      'saturday': '7:00 AM - 11:00 PM',
      'sunday': '7:00 AM - 10:00 PM',
    },
    'isOpen': true,
    'openUntil': '10:00 PM',
    'rules': [
      'No glass containers allowed',
      'Clean up after yourself',
      'Be respectful to other players',
      'No loud music after 8 PM',
      'Maximum 2 hours per session during peak hours',
    ],
  };

  @override
  void initState() {
    super.initState();
    // MVP: 3 tabs when venuesBooking=false (hide Reviews), 4 tabs when enabled
    final tabCount = FeatureFlags.venuesBooking ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venueAsync = ref.watch(venueDetailProvider(widget.venueId));

    return Scaffold(
      body: venueAsync.when(
        data: (venue) => NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(venue),
          ],
          body: _buildTabContent(venue),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load venue: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(venueDetailProvider(widget.venueId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: venueAsync.maybeWhen(
        data: (venue) => _buildBottomBar(venue),
        orElse: () => null,
      ),
    );
  }

  Widget _buildSliverAppBar(dynamic venue) {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      title: Text(venue.name),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [_buildImageCarousel(), _buildImageOverlay()],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.share), onPressed: _shareVenue),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    // MVP: Hide photo carousel when venuesBooking is disabled
    if (!FeatureFlags.venuesBooking) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                _venueData['name'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final images = _venueData['images'] as List<String>;

    return PageView.builder(
      itemCount: images.length,
      onPageChanged: (index) {
        setState(() {
          _currentImageIndex = index;
        });
      },
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image, size: 80, color: Colors.grey),
          ),
          // child: Image.network(
          //   images[index],
          //   fit: BoxFit.cover,
          // ),
        );
      },
    );
  }

  Widget _buildImageOverlay() {
    final images = _venueData['images'] as List<String>;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Stack(
        children: [
          // MVP: Hide image indicators when venuesBooking is disabled
          if (FeatureFlags.venuesBooking && images.length > 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Venue info overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _venueData['isOpen']
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _venueData['isOpen']
                              ? 'OPEN until ${_venueData['openUntil']}'
                              : 'CLOSED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // MVP: Hide rating when venuesBooking is disabled
                      if (FeatureFlags.venuesBooking)
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[300],
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_venueData['rating']} (${_venueData['reviewCount']} reviews)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Quick action buttons (Keep: Call and Directions)
                Column(
                  children: [
                    IconButton(
                      onPressed: _getDirections,
                      icon: const Icon(Icons.directions, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: _callVenue,
                      icon: const Icon(Icons.phone, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(dynamic venue) {
    // MVP: Hide Reviews tab when venuesBooking=false
    final tabs = [
      const Tab(text: 'Overview'),
      const Tab(text: 'Amenities'),
      if (FeatureFlags.venuesBooking) const Tab(text: 'Reviews'),
      const Tab(text: 'Hours'),
    ];

    final tabViews = [
      _buildOverviewTab(venue),
      _buildAmenitiesTab(venue),
      if (FeatureFlags.venuesBooking) _buildReviewsTab(),
      _buildHoursTab(venue),
    ];

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: tabs,
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabController, children: tabViews),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(dynamic venue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'About This Venue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    venue.description.isEmpty
                        ? 'No description available'
                        : venue.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sports Available
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sports, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Sports Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (venue.supportedSports as List<String>)
                        .map(
                          (sport) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSportIcon(sport),
                                  size: 16,
                                  color: Colors.blue[800],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sport,
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_venueData['features'] as List<String>).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(feature, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rules
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rule, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Venue Rules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_venueData['rules'] as List<String>).map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 18,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rule,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesTab(dynamic venue) {
    final amenitiesList = venue.amenities as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_convenience_store, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Available Amenities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  amenitiesList.isEmpty
                      ? const Text('No amenities information available')
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: amenitiesList.length,
                          itemBuilder: (context, index) {
                            final amenity = amenitiesList[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getAmenityIcon(amenity),
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      amenity,
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pricing Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Pricing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          _venueData['priceRange'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const Spacer(),
                        if (_venueData['priceRange'] == 'Free')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NO COST',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Rating Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            _venueData['rating'].toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star,
                                color: index < _venueData['rating'].floor()
                                    ? Colors.amber
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                          Text(
                            '${_venueData['reviewCount']} reviews',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            _buildRatingBar(5, 80),
                            _buildRatingBar(4, 15),
                            _buildRatingBar(3, 3),
                            _buildRatingBar(2, 1),
                            _buildRatingBar(1, 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Individual Reviews
          ...List.generate(
            3,
            (index) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue[300],
                          child: Text('U${index + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (starIndex) => Icon(
                                      Icons.star,
                                      size: 16,
                                      color: starIndex < (5 - index)
                                          ? Colors.amber
                                          : Colors.grey[300],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '2 weeks ago',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      index == 0
                          ? 'Great venue with excellent facilities. The court surface is well-maintained and the lighting is perfect for evening games.'
                          : index == 1
                          ? 'Good location and free parking. The restrooms could use some improvement but overall a solid choice.'
                          : 'Clean courts and friendly atmosphere. Definitely coming back!',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Write Review Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _writeReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Write a Review',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars'),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
            ),
          ),
          const SizedBox(width: 8),
          Text('$percentage%'),
        ],
      ),
    );
  }

  Widget _buildHoursTab(dynamic venue) {
    // Use opening and closing times from venue
    final openingTime = venue.openingTime ?? '—';
    final closingTime = venue.closingTime ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Operating Hours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Simple hours display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Hours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$openingTime - $closingTime',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(dynamic venue) {
    // Use venue data
    final priceRange =
        '\$${venue.pricePerHour.toStringAsFixed(0)}/${venue.currency}';
    final addressFirstLine = venue.addressLine1.isNotEmpty
        ? venue.addressLine1
        : 'Address not available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Contact Info (Keep visible for MVP)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priceRange,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    addressFirstLine,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action Buttons (Keep: Directions and Call)
            Row(
              children: [
                ElevatedButton(
                  onPressed: _getDirections,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Directions',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                // MVP: Hide booking button when venuesBooking=false
                if (FeatureFlags.venuesBooking) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _bookNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'soccer':
        return Icons.sports_soccer;
      case 'football':
        return Icons.sports_football;
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'free parking':
      case 'parking':
        return Icons.local_parking;
      case 'restrooms':
        return Icons.wc;
      case 'water fountain':
      case 'water':
        return Icons.water_drop;
      case 'lighting':
        return Icons.lightbulb;
      case 'seating area':
      case 'seating':
        return Icons.chair;
      case 'locker rooms':
        return Icons.lock;
      case 'snack bar':
        return Icons.restaurant;
      case 'wifi':
        return Icons.wifi;
      case 'pro shop':
        return Icons.store;
      case 'restaurant':
        return Icons.restaurant_menu;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.check_circle;
    }
  }

  void _shareVenue() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sharing venue...')));
  }

  void _toggleFavorite() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
  }

  void _getDirections() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening directions...')));
  }

  void _callVenue() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling ${_venueData['phone']}')));
  }

  void _writeReview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate this venue:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.star_border, color: Colors.amber[600]),
                ),
              ),
            ),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _bookNow() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening booking...')));
  }
}
