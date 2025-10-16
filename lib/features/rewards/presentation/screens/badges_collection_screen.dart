import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/badge.dart' as rewards_badge;
import '../../domain/entities/badge_tier.dart';
import '../controllers/badge_controller.dart';
import '../providers/rewards_providers.dart';

typedef Badge = rewards_badge.Badge;

class BadgesCollectionScreen extends ConsumerStatefulWidget {
  const BadgesCollectionScreen({super.key});

  @override
  ConsumerState<BadgesCollectionScreen> createState() => _BadgesCollectionScreenState();
}

class _BadgesCollectionScreenState extends ConsumerState<BadgesCollectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _gridAnimationController;
  
  bool _isGridView = true;
  int _showcaseLimit = 6;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    // Initialize badge data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(badgeControllerProvider.notifier).refresh();
    });
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _headerAnimationController.forward();
    _gridAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _gridAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeState = ref.watch(badgeControllerProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(badgeState),
          SliverToBoxAdapter(child: _buildCollectionStats(badgeState)),
          SliverToBoxAdapter(child: _buildFilterSection(badgeState)),
          _buildShowcaseSection(badgeState),
          _buildBadgeCollection(badgeState),
        ],
      ),
      floatingActionButton: _buildFloatingActions(badgeState),
    );
  }

  Widget _buildSliverAppBar(BadgeState state) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedBuilder(
                    animation: _headerAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - _headerAnimationController.value)),
                        child: Opacity(
                          opacity: _headerAnimationController.value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Badge Collection',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${state.userBadges.length} badges earned',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text(
          'Badges',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          color: Colors.white,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportCollection();
                break;
              case 'share':
                _shareCollection();
                break;
              case 'settings':
                _showShowcaseSettings();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 12),
                  Text('Export as Image'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 12),
                  Text('Share Collection'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 12),
                  Text('Showcase Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollectionStats(BadgeState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Collection Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(child: _buildStatCard('Total', state.userBadges.length.toString(), Icons.collections_bookmark, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Showcased', state.showcasedBadgeIds.length.toString(), Icons.star, Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Rare+', _getRareCount(state).toString(), Icons.diamond, Colors.purple)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildRarityBreakdown(state),
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms, delay: 200.ms)
      .slideY(begin: 0.3, end: 0);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityBreakdown(BadgeState state) {
    final breakdown = _getRarityBreakdown(state.userBadges);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rarity Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...BadgeTier.values.map((tier) {
          final count = breakdown[tier] ?? 0;
          final color = _getTierColor(tier);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getTierName(tier),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterSection(BadgeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                ref.read(badgeControllerProvider.notifier).updateSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Search badges...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(badgeControllerProvider.notifier).updateSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', BadgeFilter.all, state.selectedFilter),
                _buildFilterChip('Showcased', BadgeFilter.showcased, state.selectedFilter),
                _buildFilterChip('Limited', BadgeFilter.limited, state.selectedFilter),
                const SizedBox(width: 8),
                ...BadgeTier.values.map((tier) {
                  final filter = _tierToFilter(tier);
                  return _buildFilterChip(_getTierName(tier), filter, state.selectedFilter);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, BadgeFilter filter, BadgeFilter selected) {
    final isSelected = selected == filter;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          ref.read(badgeControllerProvider.notifier).updateFilter(
            selected ? filter : BadgeFilter.all,
          );
        },
        selectedColor: _getFilterColor(filter).withOpacity(0.2),
        checkmarkColor: _getFilterColor(filter),
        labelStyle: TextStyle(
          color: isSelected ? _getFilterColor(filter) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildShowcaseSection(BadgeState state) {
    if (state.showcasedBadgeIds.isEmpty) {
      return SliverToBoxAdapter(child: Container());
    }

    final showcasedBadges = state.userBadges
        .where((badge) => state.showcasedBadgeIds.contains(badge.id))
        .toList();

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Showcase',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showShowcaseManager,
                  child: const Text('Manage'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: showcasedBadges.length,
              onReorder: _reorderShowcaseBadges,
              itemBuilder: (context, index) {
                final badge = showcasedBadges[index];
                return _buildShowcaseBadgeItem(badge, index, key: ValueKey(badge.id));
              },
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: 500.ms, delay: 400.ms)
        .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildShowcaseBadgeItem(Badge badge, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTierColor(badge.tier).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTierColor(badge.tier).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getTierColor(badge.tier)),
            ),
            child: Icon(
              Icons.military_tech,
              color: _getTierColor(badge.tier),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getTierName(badge.tier),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getTierColor(badge.tier),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Icon(
            Icons.drag_handle,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCollection(BadgeState state) {
    if (state.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load badges',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(badgeControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredBadges = state.filteredBadges;

    if (filteredBadges.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No badges found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              Text(
                'Try adjusting your filters',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return _isGridView
        ? _buildBadgeGrid(filteredBadges, state)
        : _buildBadgeList(filteredBadges, state);
  }

  Widget _buildBadgeGrid(List<Badge> badges, BadgeState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final badge = badges[index];
            return _buildBadgeGridItem(badge, state, index);
          },
          childCount: badges.length,
        ),
      ),
    );
  }

  Widget _buildBadgeGridItem(Badge badge, BadgeState state, int index) {
    final isShowcased = state.showcasedBadgeIds.contains(badge.id);
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      onLongPress: () => _showBadgeActions(badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getTierColor(badge.tier).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getTierColor(badge.tier).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getTierColor(badge.tier)),
                    ),
                    child: Icon(
                      Icons.military_tech,
                      color: _getTierColor(badge.tier),
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Badge name
                  Text(
                    badge.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Tier indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTierColor(badge.tier).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTierName(badge.tier),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getTierColor(badge.tier),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Showcase indicator
            if (isShowcased)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            
            // Limited edition indicator
            if (badge.isLimitedEdition)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIMITED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(
        duration: 300.ms,
        delay: Duration(milliseconds: index * 50),
      )
      .scale(
        begin: const Offset(0.8, 0.8),
        duration: 300.ms,
        delay: Duration(milliseconds: index * 50),
      );
  }

  Widget _buildBadgeList(List<Badge> badges, BadgeState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final badge = badges[index];
          return _buildBadgeListItem(badge, state, index);
        },
        childCount: badges.length,
      ),
    );
  }

  Widget _buildBadgeListItem(Badge badge, BadgeState state, int index) {
    final isShowcased = state.showcasedBadgeIds.contains(badge.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTierColor(badge.tier).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getTierColor(badge.tier).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getTierColor(badge.tier)),
            ),
            child: Icon(
              Icons.military_tech,
              color: _getTierColor(badge.tier),
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Badge info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isShowcased) ...[
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                    ],
                    if (badge.isLimitedEdition)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LIMITED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTierColor(badge.tier).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTierName(badge.tier),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTierColor(badge.tier),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      'Rarity: ${badge.rarityScore}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  badge.unlockMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            onSelected: (value) => _handleBadgeAction(value, badge),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 12),
                    Text('View Details'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: isShowcased ? 'remove_showcase' : 'add_showcase',
                child: Row(
                  children: [
                    Icon(isShowcased ? Icons.star : Icons.star_border),
                    const SizedBox(width: 12),
                    Text(isShowcased ? 'Remove from Showcase' : 'Add to Showcase'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 12),
                    Text('Share Badge'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(
        duration: 300.ms,
        delay: Duration(milliseconds: index * 100),
      )
      .slideX(
        begin: 0.3,
        duration: 300.ms,
        delay: Duration(milliseconds: index * 100),
      );
  }

  Widget _buildFloatingActions(BadgeState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.showcasedBadgeIds.isNotEmpty)
          FloatingActionButton(
            heroTag: "showcase",
            onPressed: _previewShowcase,
            backgroundColor: Colors.amber,
            child: const Icon(Icons.visibility),
          ),
        
        const SizedBox(height: 16),
        
        FloatingActionButton.extended(
          heroTag: "export",
          onPressed: _exportCollection,
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.download),
          label: const Text('Export'),
        ),
      ],
    );
  }

  // Helper methods
  int _getRareCount(BadgeState state) {
    return state.userBadges.where((badge) {
      return badge.tier == BadgeTier.gold || 
             badge.tier == BadgeTier.platinum || 
             badge.tier == BadgeTier.diamond;
    }).length;
  }

  Map<BadgeTier, int> _getRarityBreakdown(List<Badge> badges) {
    final breakdown = <BadgeTier, int>{};
    for (final badge in badges) {
      breakdown[badge.tier] = (breakdown[badge.tier] ?? 0) + 1;
    }
    return breakdown;
  }

  Color _getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return Colors.brown;
      case BadgeTier.silver:
        return Colors.grey;
      case BadgeTier.gold:
        return Colors.amber;
      case BadgeTier.platinum:
        return Colors.blue;
      case BadgeTier.diamond:
        return Colors.purple;
    }
  }

  String _getTierName(BadgeTier tier) {
    return tier.name.toUpperCase();
  }

  BadgeFilter _tierToFilter(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return BadgeFilter.bronze;
      case BadgeTier.silver:
        return BadgeFilter.silver;
      case BadgeTier.gold:
        return BadgeFilter.gold;
      case BadgeTier.platinum:
        return BadgeFilter.platinum;
      case BadgeTier.diamond:
        return BadgeFilter.diamond;
    }
  }

  Color _getFilterColor(BadgeFilter filter) {
    switch (filter) {
      case BadgeFilter.all:
        return Theme.of(context).primaryColor;
      case BadgeFilter.showcased:
        return Colors.amber;
      case BadgeFilter.limited:
        return Colors.red;
      case BadgeFilter.bronze:
        return Colors.brown;
      case BadgeFilter.silver:
        return Colors.grey;
      case BadgeFilter.gold:
        return Colors.amber;
      case BadgeFilter.platinum:
        return Colors.blue;
      case BadgeFilter.diamond:
        return Colors.purple;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  // Action methods
  void _showBadgeDetails(Badge badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBadgeDetailsModal(badge),
    );
  }

  Widget _buildBadgeDetailsModal(Badge badge) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge header
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _getTierColor(badge.tier).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _getTierColor(badge.tier), width: 2),
                        ),
                        child: Icon(
                          Icons.military_tech,
                          color: _getTierColor(badge.tier),
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getTierColor(badge.tier).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getTierName(badge.tier),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getTierColor(badge.tier),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Badge details
                  _buildDetailRow('Unlock Message', badge.unlockMessage),
                  _buildDetailRow('Rarity Score', '${badge.rarityScore}/100'),
                  _buildDetailRow('Style', badge.style.name.toUpperCase()),
                  if (badge.isLimitedEdition) ...[
                    _buildDetailRow('Edition', 'Limited Edition'),
                    if (badge.maxOwners != null)
                      _buildDetailRow('Max Owners', '${badge.currentOwners}/${badge.maxOwners}'),
                  ],
                  _buildDetailRow('Earned', _formatDate(badge.createdAt)),
                  
                  const Spacer(),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareBadge(badge);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleShowcase(badge);
                          },
                          icon: Icon(ref.read(badgeControllerProvider).showcasedBadgeIds.contains(badge.id)
                              ? Icons.star
                              : Icons.star_border),
                          label: Text(ref.read(badgeControllerProvider).showcasedBadgeIds.contains(badge.id)
                              ? 'Remove'
                              : 'Showcase'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeActions(Badge badge) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showBadgeDetails(badge);
              },
            ),
            ListTile(
              leading: Icon(ref.read(badgeControllerProvider).showcasedBadgeIds.contains(badge.id)
                  ? Icons.star
                  : Icons.star_border),
              title: Text(ref.read(badgeControllerProvider).showcasedBadgeIds.contains(badge.id)
                  ? 'Remove from Showcase'
                  : 'Add to Showcase'),
              onTap: () {
                Navigator.pop(context);
                _toggleShowcase(badge);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Badge'),
              onTap: () {
                Navigator.pop(context);
                _shareBadge(badge);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleBadgeAction(String action, Badge badge) {
    switch (action) {
      case 'details':
        _showBadgeDetails(badge);
        break;
      case 'add_showcase':
      case 'remove_showcase':
        _toggleShowcase(badge);
        break;
      case 'share':
        _shareBadge(badge);
        break;
    }
  }

  void _toggleShowcase(Badge badge) {
    final controller = ref.read(badgeControllerProvider.notifier);
    final isShowcased = ref.read(badgeControllerProvider).showcasedBadgeIds.contains(badge.id);
    
    if (isShowcased) {
      controller.removeFromShowcase(badge.id);
    } else {
      controller.addToShowcase(badge.id);
    }
  }

  void _reorderShowcaseBadges(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final showcasedBadges = ref.read(badgeControllerProvider).userBadges
        .where((badge) => ref.read(badgeControllerProvider).showcasedBadgeIds.contains(badge.id))
        .toList();
    
    final item = showcasedBadges.removeAt(oldIndex);
    showcasedBadges.insert(newIndex, item);
    
    final newOrder = showcasedBadges.map((badge) => badge.id).toList();
    ref.read(badgeControllerProvider.notifier).reorderShowcase(newOrder);
  }

  void _showShowcaseSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Showcase Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Showcase Limit: $_showcaseLimit'),
            Slider(
              value: _showcaseLimit.toDouble(),
              min: 3,
              max: 12,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _showcaseLimit = value.round();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showShowcaseManager() {
    // TODO: Implement showcase manager
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Showcase manager not implemented yet')),
    );
  }

  void _previewShowcase() {
    // TODO: Implement showcase preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Showcase preview not implemented yet')),
    );
  }

  void _shareBadge(Badge badge) {
    Share.share('Check out my ${badge.name} badge! ${badge.unlockMessage}');
  }

  void _shareCollection() {
    final badgeCount = ref.read(badgeControllerProvider).userBadges.length;
    Share.share('Check out my badge collection! I have $badgeCount badges in Dabbler.');
  }

  void _exportCollection() async {
    // TODO: Implement collection export as image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}