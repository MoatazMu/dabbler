import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import '../../themes/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../themes/design_system.dart';
import 'match_list_screen.dart';
import 'package:dabbler/features/venues/presentation/features/venue_detail_screen.dart';
import 'package:dabbler/features/games/providers/games_providers.dart';
import 'package:dabbler/features/games/presentation/controllers/venues_controller.dart'
    as vc;

class VenueCard extends StatelessWidget {
  final Map<String, dynamic> venue;
  final VoidCallback? onTap;
  final bool isLoading;

  const VenueCard({
    super.key,
    required this.venue,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeletonCard();
    }

    final images = (venue['images'] as List<dynamic>?)?.cast<String>() ?? [];
    final name = venue['name'] as String? ?? 'Unknown Venue';
    final area = venue['location'] as String? ?? 'Location not available';
    final sports = (venue['sports'] as List<dynamic>?)?.cast<String>() ?? [];
    final rating = (venue['rating'] as num?)?.toDouble() ?? 0.0;
    final isClosed = venue['isOpen'] == false;
    final slots =
        (venue['slots'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final reviews =
        (venue['reviews'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    final distance = venue['distance'] as String? ?? '';
    final hasQuickSlot = slots.any(
      (slot) => slot['available'] == true && slot['isSoon'] == true,
    );
    final ctaEnabled = !isClosed && (hasQuickSlot || slots.isNotEmpty);
    final showRating = reviews.length >= 3 && rating >= 3.0;
    final maxNameLength = 26;
    final displayName = name.length > maxNameLength
        ? '${name.substring(0, maxNameLength)}…'
        : name;
    final maxSports = 3;
    final visibleSports = sports.take(maxSports).toList();
    final overflowCount = sports.length - maxSports;
    final thumbnail = images.isNotEmpty ? images.first : null;

    return GestureDetector(
      onTap: ctaEnabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                color: context.colors.primary.withValues(alpha: 0.08),
              ),
              child: Stack(
                children: [
                  if (thumbnail != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        thumbnail,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackImage(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildImagePlaceholder();
                        },
                      ),
                    )
                  else
                    _buildFallbackImage(),
                  // Status badge
                  if (isClosed)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Closed',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Rating badge
                  if (showRating)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Venue info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    displayName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          area,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Sports chips and distance
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            ...visibleSports.map(
                              (sport) => _buildSportChip(sport),
                            ),
                            if (overflowCount > 0)
                              _buildOverflowChip(overflowCount),
                          ],
                        ),
                      ),
                      if (distance.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.navigation,
                                size: 12,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                distance,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // CTA Button
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: ctaEnabled ? onTap : null,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: isClosed ? Colors.grey[400] : context.colors.primary,
                  //       foregroundColor: Colors.white,
                  //       disabledBackgroundColor: Colors.grey[300],
                  //       minimumSize: const Size(0, 32),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       padding: const EdgeInsets.symmetric(horizontal: 0),
                  //       elevation: 0,
                  //     ),
                  //     child: Text(
                  //       ctaLabel,
                  //       style: context.textTheme.bodySmall?.copyWith(
                  //         fontWeight: FontWeight.w700,
                  //         color: Colors.white,
                  //         fontSize: 12,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportChip(String sport) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DS.gap6,
        vertical: DS.gap2,
      ),
      decoration: BoxDecoration(
        color: DS.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSportIcon(sport), size: 12, color: DS.primary),
          const SizedBox(width: 4),
          Text(
            sport,
            style: DS.caption.copyWith(
              color: DS.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverflowChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DS.gap6,
        vertical: DS.gap2,
      ),
      decoration: BoxDecoration(
        color: DS.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+$count',
        style: DS.caption.copyWith(
          color: DS.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return LucideIcons.circle;
      case 'cricket':
        return LucideIcons.circle;
      case 'padel':
        return LucideIcons.square;
      case 'tennis':
        return LucideIcons.square;
      case 'basketball':
        return LucideIcons.circle;
      case 'volleyball':
        return LucideIcons.circle;
      default:
        return LucideIcons.activity;
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 24, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: DS.caption.copyWith(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: DS.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton thumbnail
          Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          // Skeleton content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DS.gap16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skeleton title
                  DS.skeleton(height: 18, width: 150),
                  const SizedBox(height: DS.gap4),

                  // Skeleton location
                  DS.skeleton(height: 14, width: 100),
                  const SizedBox(height: DS.gap8),

                  // Skeleton chips
                  Row(
                    children: [
                      DS.skeleton(height: 20, width: 60),
                      const SizedBox(width: DS.gap4),
                      DS.skeleton(height: 20, width: 50),
                    ],
                  ),

                  const SizedBox(height: DS.gap8),

                  // Skeleton button
                  DS.skeleton(height: 32, width: double.infinity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExploreScreen extends StatefulWidget {
  final String? initialTab;
  final Map<String, dynamic>? initialFilters;

  const ExploreScreen({super.key, this.initialTab, this.initialFilters});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController; // Games/Venues
  int _selectedSportIndex = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _sports = [
    {
      'name': 'Football',
      'icon': LucideIcons.circle,
      'color': Colors.green,
      'description': 'Find football games near you',
    },
    {
      'name': 'Cricket',
      'icon': LucideIcons.circle,
      'color': Colors.orange,
      'description': 'Join cricket games and tournaments',
    },
    {
      'name': 'Padel',
      'icon': LucideIcons.square,
      'color': Colors.blue,
      'description': 'Discover padel courts and players',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchController.text = _searchQuery;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(actionIcon: Iconsax.search_normal_copy),
      body: Column(
        children: [
          // Enhanced Header
          _buildEnhancedHeader(),

          // Sports Chips (for filtering)
          _buildSportsChips(),

          // Main TabBarView
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // Games Tab: Filtered by selected sport
                MatchListScreen(
                  sport: _sports[_selectedSportIndex]['name'],
                  sportColor: _sports[_selectedSportIndex]['color'],
                  searchQuery: _searchQuery,
                ),
                // Venues Tab: Filtered by selected sport
                _buildVenuesTab(
                  _sports[_selectedSportIndex]['name'],
                  _searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      color: const Color(0xFF813FD6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _isSearching
                      ? SizedBox(
                          height: 48,
                          child: TextField(
                            minLines: 1,
                            maxLines: 1,
                            controller: _searchController,
                            autofocus: true,
                            style: context.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search games or venues',
                              hintStyle: context.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore Sports',
                              style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find and join exciting games',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.push(RoutePaths.createGame),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Create game'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF813FD6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if (!_isSearching) ...[
                  // IconButton(
                  //   icon: Icon(
                  //     LucideIcons.filter,
                  //     size: 14,
                  //     color: context.colors.primary,
                  //   ),
                  //   onPressed: _showFilterModal,
                  //   tooltip: 'Open Filters',
                  //   splashRadius: 20,
                  // ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.filter,
                      color: context.colors.primary,
                    ),
                    onPressed: () {},
                    tooltip: 'Open Filters',
                    splashRadius: 20,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.search, color: Colors.white),
                    onPressed: _startSearch,
                  ),
                ],
                if (_isSearching)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _stopSearch,
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _mainTabController,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.gamepad2, size: 20),
                        SizedBox(width: 8),
                        Text('Games'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.mapPin, size: 20),
                        SizedBox(width: 8),
                        Text('Venues'),
                      ],
                    ),
                  ),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsChips() {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      // margin: const EdgeInsets.only(right: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(_sports.length, (index) {
              final sport = _sports[index];
              final isSelected = _selectedSportIndex == index;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sport['icon'],
                        color: isSelected
                            ? sport['color']
                            : context.colors.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(sport['name']),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: sport['color'].withOpacity(0.15),
                  backgroundColor: context.colors.surface,
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? sport['color']
                        : context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedSportIndex = index;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? sport['color']
                          : context.colors.outline.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildVenuesTab(String selectedSport, String searchQuery) {
    return _VenuesTabContent(
      selectedSport: selectedSport,
      searchQuery: searchQuery,
    );
  }
}

class _VenuesTabContent extends ConsumerStatefulWidget {
  final String selectedSport;
  final String searchQuery;
  const _VenuesTabContent({
    required this.selectedSport,
    required this.searchQuery,
  });

  @override
  ConsumerState<_VenuesTabContent> createState() => _VenuesTabContentState();
}

class _VenuesTabContentState extends ConsumerState<_VenuesTabContent> {
  final ScrollController _scrollController = ScrollController();

  // Advanced filter state
  String? _selectedSport;
  String? _selectedArea;
  RangeValues _selectedPriceRange = const RangeValues(0, 500);
  double _selectedRating = 0;
  Set<String> _selectedAmenities = {};

  void _showFilterModal() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Filter Venues',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sport Type
                    Text(
                      'Sport Type',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          [
                            'Football',
                            'Tennis',
                            'Padel',
                            'Basketball',
                            'Other',
                          ].map((sport) {
                            return ChoiceChip(
                              label: Text(sport),
                              selected: _selectedSport == sport,
                              onSelected: (selected) {
                                setModalState(
                                  () =>
                                      _selectedSport = selected ? sport : null,
                                );
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Area
                    Text('Area', style: Theme.of(context).textTheme.bodyMedium),
                    DropdownButton<String>(
                      value: _selectedArea,
                      hint: const Text('Select Area'),
                      isExpanded: true,
                      items:
                          [
                            'Downtown',
                            'Jumeirah',
                            'Marina',
                            'Business Bay',
                            'Other',
                          ].map((area) {
                            return DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            );
                          }).toList(),
                      onChanged: (value) =>
                          setModalState(() => _selectedArea = value),
                    ),
                    const SizedBox(height: 20),
                    // Price Range
                    Text(
                      'Price Range (AED)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    RangeSlider(
                      values: _selectedPriceRange,
                      min: 0,
                      max: 500,
                      divisions: 10,
                      labels: RangeLabels(
                        _selectedPriceRange.start.round().toString(),
                        _selectedPriceRange.end.round().toString(),
                      ),
                      onChanged: (values) =>
                          setModalState(() => _selectedPriceRange = values),
                    ),
                    const SizedBox(height: 20),
                    // Rating
                    Text(
                      'Minimum Rating',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: _selectedRating,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: _selectedRating == 0
                          ? 'Any'
                          : _selectedRating.toStringAsFixed(1),
                      onChanged: (value) =>
                          setModalState(() => _selectedRating = value),
                    ),
                    const SizedBox(height: 20),
                    // Amenities
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          [
                            'Parking',
                            'Showers',
                            'Indoor',
                            'Outdoor',
                            'Cafeteria',
                          ].map((amenity) {
                            return FilterChip(
                              label: Text(amenity),
                              selected: _selectedAmenities.contains(amenity),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    _selectedAmenities.add(amenity);
                                  } else {
                                    _selectedAmenities.remove(amenity);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedSport = null;
                                _selectedArea = null;
                                _selectedPriceRange = const RangeValues(0, 500);
                                _selectedRating = 0;
                                _selectedAmenities.clear();
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop({
                                'sport': _selectedSport,
                                'area': _selectedArea,
                                'priceRange': _selectedPriceRange,
                                'rating': _selectedRating,
                                'amenities': _selectedAmenities,
                              });
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedSport = result['sport'];
        _selectedArea = result['area'];
        _selectedPriceRange = result['priceRange'];
        _selectedRating = result['rating'];
        _selectedAmenities = Set<String>.from(result['amenities']);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load venues with sport filter on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter();
    });
  }

  @override
  void didUpdateWidget(_VenuesTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSport != widget.selectedSport) {
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Infinite scroll can be implemented if needed
  }

  void _applyFilter() {
    // Update venues controller with sport filter
    final filters = vc.VenueFilters(
      sports: [widget.selectedSport],
      minRating: _selectedRating > 0 ? _selectedRating : null,
      minPricePerHour: _selectedPriceRange.start > 0
          ? _selectedPriceRange.start
          : null,
      maxPricePerHour: _selectedPriceRange.end < 500
          ? _selectedPriceRange.end
          : null,
    );

    ref.read(venuesControllerProvider.notifier).updateFilters(filters);
  }

  Future<void> _refreshVenues() async {
    await ref.read(venuesControllerProvider.notifier).refresh();
  }

  void _onVenueTap(String venueId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VenueDetailScreen(venueId: venueId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venuesState = ref.watch(venuesControllerProvider);
    final venues = venuesState.venues;

    // Apply search query filter
    final query = widget.searchQuery.toLowerCase();
    final filteredVenues = query.isEmpty
        ? venues
        : venues.where((venueWithDistance) {
            final name = venueWithDistance.venue.name.toLowerCase();
            final city = venueWithDistance.venue.city.toLowerCase();
            return name.contains(query) || city.contains(query);
          }).toList();

    // Show error state
    if (venuesState.error != null &&
        filteredVenues.isEmpty &&
        !venuesState.isLoading) {
      return _buildErrorState();
    }

    // Show empty state
    if (filteredVenues.isEmpty && !venuesState.isLoading) {
      return _buildEmptyState();
    }

    // Show venues list
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(
              bottom: BorderSide(
                color: context.colors.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 16,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Near Dubai, UAE',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.filter,
                        size: 14,
                        color: context.colors.primary,
                      ),
                      onPressed: _showFilterModal,
                      tooltip: 'Open Filters',
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshVenues,
            child: venuesState.isLoading && filteredVenues.isEmpty
                ? _buildLoadingState()
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: filteredVenues.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final venueWithDistance = filteredVenues[index];
                      final venue = venueWithDistance.venue;

                      // Convert Venue entity to Map for VenueCard
                      final venueMap = {
                        'id': venue.id,
                        'name': venue.name,
                        'location': '${venue.city}, ${venue.country}',
                        'sports': venue.supportedSports,
                        'images': [],
                        'rating': venue.rating,
                        'isOpen': true,
                        'slots': [],
                        'reviews': List.generate(venue.totalRatings, (_) => {}),
                        'distance': venueWithDistance.formattedDistance,
                        'price': venue.pricePerHour.toString(),
                        'amenities': venue.amenities,
                      };

                      return VenueCard(
                        venue: venueMap,
                        onTap: () => _onVenueTap(venue.id),
                        isLoading: false,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          VenueCard(venue: const {}, isLoading: true),
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
              child: Icon(LucideIcons.wifiOff, size: 48, color: DS.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load venues',
              style: DS.headline.copyWith(
                fontWeight: FontWeight.w700,
                color: DS.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: DS.body.copyWith(color: DS.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshVenues,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
              style: DS.primaryButton,
            ),
          ],
        ),
      ),
    );
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
                color: DS.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(LucideIcons.mapPin, size: 48, color: DS.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${widget.selectedSport} venues found',
              style: DS.headline.copyWith(
                fontWeight: FontWeight.w700,
                color: DS.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try broadening your filters or check back later',
              style: DS.body.copyWith(color: DS.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshVenues,
              icon: const Icon(LucideIcons.filter),
              label: const Text('Adjust Filters'),
              style: DS.primaryButton,
            ),
          ],
        ),
      ),
    );
  }
}
