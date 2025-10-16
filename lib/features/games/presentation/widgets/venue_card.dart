import 'package:flutter/material.dart';

class VenueCard extends StatelessWidget {
  final String id;
  final String name;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final double distance; // in km
  final List<String> supportedSports;
  final String priceRange; // '$', '$$', '$$$'
  final bool isFeatured;
  final List<String> amenities; // ['parking', 'shower', 'equipment']
  final VoidCallback? onTap;

  const VenueCard({
    super.key,
    required this.id,
    required this.name,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.supportedSports,
    required this.priceRange,
    this.isFeatured = false,
    required this.amenities,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(context),
              _buildContentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or placeholder
          imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Top badges
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isFeatured) _buildFeaturedBadge(),
                const Spacer(),
                _buildDistanceBadge(),
              ],
            ),
          ),
          
          // Bottom content overlay
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildRatingDisplay(),
                    const SizedBox(width: 8),
                    _buildPriceIndicator(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'FEATURED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${distance.toStringAsFixed(1)}km',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRatingDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' ($reviewCount)',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priceRange,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSportsSection(),
          const SizedBox(height: 12),
          _buildAmenitiesSection(),
        ],
      ),
    );
  }

  Widget _buildSportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sports Available',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: supportedSports.take(4).map((sport) {
            final sportData = _getSportData(sport);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sportData['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sportData['color'].withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sportData['icon'],
                    size: 16,
                    color: sportData['color'],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sport,
                    style: TextStyle(
                      fontSize: 12,
                      color: sportData['color'],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (supportedSports.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${supportedSports.length - 4} more',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...amenities.take(4).map((amenity) {
              final amenityData = _getAmenityData(amenity);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: amenityData['label'],
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      amenityData['icon'],
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }),
            if (amenities.length > 4)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '+${amenities.length - 4}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _getSportData(String sport) {
    switch (sport.toLowerCase()) {
      case 'soccer':
      case 'football':
        return {
          'icon': Icons.sports_soccer,
          'color': Colors.green,
        };
      case 'basketball':
        return {
          'icon': Icons.sports_basketball,
          'color': Colors.orange,
        };
      case 'tennis':
        return {
          'icon': Icons.sports_tennis,
          'color': Colors.blue,
        };
      case 'volleyball':
        return {
          'icon': Icons.sports_volleyball,
          'color': Colors.purple,
        };
      case 'baseball':
        return {
          'icon': Icons.sports_baseball,
          'color': Colors.brown,
        };
      case 'badminton':
        return {
          'icon': Icons.sports_tennis,
          'color': Colors.teal,
        };
      case 'swimming':
        return {
          'icon': Icons.pool,
          'color': Colors.cyan,
        };
      case 'gym':
      case 'fitness':
        return {
          'icon': Icons.fitness_center,
          'color': Colors.red,
        };
      default:
        return {
          'icon': Icons.sports,
          'color': Colors.grey,
        };
    }
  }

  Map<String, dynamic> _getAmenityData(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'parking':
        return {
          'icon': Icons.local_parking,
          'label': 'Parking Available',
        };
      case 'shower':
      case 'showers':
        return {
          'icon': Icons.shower,
          'label': 'Shower Facilities',
        };
      case 'equipment':
        return {
          'icon': Icons.sports,
          'label': 'Equipment Rental',
        };
      case 'lockers':
        return {
          'icon': Icons.lock,
          'label': 'Lockers Available',
        };
      case 'cafe':
      case 'restaurant':
        return {
          'icon': Icons.restaurant,
          'label': 'Food & Drinks',
        };
      case 'wifi':
        return {
          'icon': Icons.wifi,
          'label': 'Free WiFi',
        };
      case 'ac':
      case 'air_conditioning':
        return {
          'icon': Icons.ac_unit,
          'label': 'Air Conditioning',
        };
      case 'first_aid':
        return {
          'icon': Icons.medical_services,
          'label': 'First Aid',
        };
      case 'accessibility':
        return {
          'icon': Icons.accessible,
          'label': 'Wheelchair Accessible',
        };
      case 'lighting':
        return {
          'icon': Icons.lightbulb,
          'label': 'Good Lighting',
        };
      default:
        return {
          'icon': Icons.check_circle,
          'label': amenity,
        };
    }
  }
}
