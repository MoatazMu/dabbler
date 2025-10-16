import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/tier.dart';
import '../controllers/tier_controller.dart';
import '../providers/rewards_providers.dart';

class TierProgressScreen extends ConsumerStatefulWidget {
  const TierProgressScreen({super.key});

  @override
  ConsumerState<TierProgressScreen> createState() => _TierProgressScreenState();
}

class _TierProgressScreenState extends ConsumerState<TierProgressScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _tierAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _tierAnimation;
  
  int _selectedTabIndex = 0;
  bool _showAllTiers = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    // Initialize tier data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tierControllerProvider.notifier).initialize();
    });
  }

  void _setupAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _tierAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    );
    _tierAnimation = CurvedAnimation(
      parent: _tierAnimationController,
      curve: Curves.elasticOut,
    );
    
    _tierAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _tierAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierState = ref.watch(tierControllerProvider);
    
    // Start progress animation when data loads
    if (!tierState.isLoading && tierState.currentTier != null) {
      _progressAnimationController.forward();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(tierState),
          SliverToBoxAdapter(child: _buildCurrentTierSection(tierState)),
          SliverToBoxAdapter(child: _buildTabSection()),
          _buildTabContent(tierState),
        ],
      ),
      floatingActionButton: _buildFloatingActions(tierState),
    );
  }

  Widget _buildSliverAppBar(TierState state) {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getTierColor(state.currentTier?.level),
                _getTierColor(state.currentTier?.level).withOpacity(0.7),
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
                    animation: _tierAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + 0.2 * _tierAnimation.value,
                        child: Opacity(
                          opacity: _tierAnimation.value,
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  _getTierIcon(state.currentTier?.level),
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              
                              const SizedBox(width: 20),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Tier',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.currentTier?.level.displayName ?? 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Level ${state.currentTier?.level.level ?? 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
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
          'Tier Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareTierProgress(state),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'history':
                _showTierHistory(state);
                break;
              case 'all_tiers':
                setState(() => _showAllTiers = !_showAllTiers);
                break;
              case 'benefits_guide':
                _showBenefitsGuide();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 12),
                  Text('Tier History'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'all_tiers',
              child: Row(
                children: [
                  Icon(_showAllTiers ? Icons.visibility_off : Icons.visibility),
                  const SizedBox(width: 12),
                  Text(_showAllTiers ? 'Hide All Tiers' : 'Show All Tiers'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'benefits_guide',
              child: Row(
                children: [
                  Icon(Icons.help_outline),
                  SizedBox(width: 12),
                  Text('Benefits Guide'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentTierSection(TierState state) {
    if (state.isLoading) {
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
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null) {
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
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load tier data',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(tierControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final progressSummary = state.progressSummary;

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
          // Next tier section
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Progress to Next Tier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress visualization
          _buildProgressVisualization(state, progressSummary),
          
          const SizedBox(height: 20),
          
          // Progress stats
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  'Current Points', 
                  progressSummary.currentPoints.toStringAsFixed(0), 
                  Icons.stars, 
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat(
                  'Points Needed', 
                  progressSummary.pointsNeeded.toStringAsFixed(0), 
                  Icons.flag, 
                  Colors.red,
                ),
              ),
              if (progressSummary.estimatedDaysToNext != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressStat(
                    'Est. Days', 
                    '${progressSummary.estimatedDaysToNext}', 
                    Icons.schedule, 
                    Colors.blue,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Benefits and privileges count
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  'Benefits', 
                  '${progressSummary.benefitsCount}', 
                  Icons.card_giftcard, 
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat(
                  'Privileges', 
                  '${progressSummary.privilegesCount}', 
                  Icons.verified_user, 
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.3, end: 0);
  }

  Widget _buildProgressVisualization(TierState state, TierProgressSummary summary) {
    return Column(
      children: [
        // Next tier info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTierColor(state.nextTier).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getTierColor(state.nextTier)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getTierIcon(state.nextTier),
                    color: _getTierColor(state.nextTier),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    summary.nextTierName,
                    style: TextStyle(
                      color: _getTierColor(state.nextTier),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '${(summary.progressPercentage).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getTierColor(state.nextTier),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Animated progress bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value * (summary.progressPercentage / 100),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTierColor(state.nextTier),
                    ),
                    minHeight: 12,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Progress milestones
                _buildProgressMilestones(state, summary),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressMilestones(TierState state, TierProgressSummary summary) {
    final milestones = [0.0, 25.0, 50.0, 75.0, 100.0];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: milestones.map((milestone) {
        final isReached = summary.progressPercentage >= milestone;
        final isNext = milestone == 100.0;
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isReached 
                ? _getTierColor(state.currentTier?.level)
                : isNext 
                    ? _getTierColor(state.nextTier)
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Benefits', 0),
          ),
          Expanded(
            child: _buildTabButton('Comparison', 1),
          ),
          if (_showAllTiers)
            Expanded(
              child: _buildTabButton('All Tiers', 2),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(TierState state) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildBenefitsTab(state);
      case 1:
        return _buildComparisonTab(state);
      case 2:
        return _buildAllTiersTab(state);
      default:
        return _buildBenefitsTab(state);
    }
  }

  Widget _buildBenefitsTab(TierState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final benefit = state.currentBenefits[index];
            return _buildBenefitCard(benefit, index);
          },
          childCount: state.currentBenefits.length,
        ),
      ),
    );
  }

  Widget _buildBenefitCard(TierBenefit benefit, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBenefitColor(benefit.type).withOpacity(0.3)),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getBenefitColor(benefit.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getBenefitIcon(benefit.type),
              color: _getBenefitColor(benefit.type),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        benefit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: benefit.isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        benefit.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  benefit.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  _getBenefitTypeLabel(benefit.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getBenefitColor(benefit.type),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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

  Widget _buildComparisonTab(TierState state) {
    final comparison = state.tierComparison;
    
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Current tier section
          _buildComparisonSection(
            'Current Tier Benefits',
            comparison.currentBenefits,
            _getTierColor(state.currentTier?.level),
            Icons.check_circle,
          ),
          
          const SizedBox(height: 24),
          
          // Benefits to unlock section
          if (comparison.benefitsToUnlock.isNotEmpty) ...[
            _buildComparisonSection(
              'Benefits to Unlock',
              comparison.benefitsToUnlock,
              _getTierColor(state.nextTier),
              Icons.lock_outline,
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Privileges to unlock
          if (comparison.privilegesToUnlock.isNotEmpty) ...[
            _buildPrivilegesSection(
              'Privileges to Unlock',
              comparison.privilegesToUnlock,
              _getTierColor(state.nextTier),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildComparisonSection(
    String title,
    List<TierBenefit> benefits,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        ...benefits.asMap().entries.map((entry) {
          final index = entry.key;
          final benefit = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        benefit.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(
              duration: 300.ms,
              delay: Duration(milliseconds: index * 100),
            )
            .slideX(
              begin: 0.2,
              duration: 300.ms,
              delay: Duration(milliseconds: index * 100),
            );
        }),
      ],
    );
  }

  Widget _buildPrivilegesSection(
    String title,
    Map<String, bool> privileges,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        ...privileges.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final privilegeEntry = entry.value;
          final privilegeName = privilegeEntry.key;
          final isAvailable = privilegeEntry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAvailable 
                  ? color.withOpacity(0.1) 
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAvailable 
                    ? color.withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAvailable ? Icons.lock_open : Icons.lock_outline,
                  color: isAvailable ? color : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatPrivilegeName(privilegeName),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isAvailable ? color : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(
              duration: 200.ms,
              delay: Duration(milliseconds: index * 50),
            );
        }),
      ],
    );
  }

  Widget _buildAllTiersTab(TierState state) {
    final allTiers = TierLevel.values;
    
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tier = allTiers[index];
            final isCurrentTier = state.currentTier?.level == tier;
            final isPastTier = (state.currentTier?.level.level ?? 0) > tier.level;
            final isNextTier = state.nextTier == tier;
            
            return _buildTierCard(tier, isCurrentTier, isPastTier, isNextTier, index);
          },
          childCount: allTiers.length,
        ),
      ),
    );
  }

  Widget _buildTierCard(TierLevel tier, bool isCurrent, bool isPast, bool isNext, int index) {
    Color cardColor = Colors.grey;
    if (isCurrent) cardColor = _getTierColor(tier);
    if (isPast) cardColor = Colors.green;
    if (isNext) cardColor = Colors.orange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.3), width: isCurrent ? 2 : 1),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardColor),
            ),
            child: Icon(
              _getTierIcon(tier),
              color: cardColor,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tier.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isPast)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Level ${tier.level}',
                  style: TextStyle(
                    fontSize: 14,
                    color: cardColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${tier.minPoints.toStringAsFixed(0)}+ points - ${tier.maxPoints.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showTierDetails(tier),
            color: cardColor,
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

  Widget _buildFloatingActions(TierState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "refresh",
          onPressed: () => ref.read(tierControllerProvider.notifier).refresh(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.refresh),
        ),
        
        const SizedBox(height: 16),
        
        FloatingActionButton.extended(
          heroTag: "share",
          onPressed: () => _shareTierProgress(state),
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.share),
          label: const Text('Share Progress'),
        ),
      ],
    );
  }

  // Helper methods
  Color _getTierColor(TierLevel? tier) {
    if (tier == null) return Colors.grey;
    
    switch (tier.level) {
      case 1: return Colors.brown;
      case 2: return Colors.grey;
      case 3: return Colors.green;
      case 4: return Colors.blue;
      case 5: return Colors.purple;
      case 6: return Colors.orange;
      case 7: return Colors.red;
      case 8: return Colors.pink;
      case 9: return Colors.teal;
      case 10: return Colors.indigo;
      case 11: return Colors.amber;
      case 12: return Colors.deepOrange;
      case 13: return Colors.deepPurple;
      case 14: return Colors.cyan;
      case 15: return Colors.black;
    }
    return Colors.grey;
  }

  IconData _getTierIcon(TierLevel? tier) {
    if (tier == null) return Icons.emoji_nature;
    
    switch (tier.level) {
      case 1: return Icons.emoji_nature;
      case 2: return Icons.local_florist;
      case 3: return Icons.park;
      case 4: return Icons.nature;
      case 5: return Icons.forest;
      case 6: return Icons.landscape;
      case 7: return Icons.terrain;
      case 8: return Icons.hiking;
      case 9: return Icons.explore;
      case 10: return Icons.psychology;
      case 11: return Icons.auto_awesome;
      case 12: return Icons.star;
      case 13: return Icons.military_tech;
      case 14: return Icons.workspace_premium;
      case 15: return Icons.diamond;
    }
    return Icons.help;
  }

  Color _getBenefitColor(BenefitType type) {
    switch (type) {
      case BenefitType.pointsBonus:
        return Colors.amber;
      case BenefitType.multiplier:
        return Colors.purple;
      case BenefitType.feature:
        return Colors.blue;
      case BenefitType.access:
        return Colors.green;
      case BenefitType.cosmetic:
        return Colors.pink;
    }
  }

  IconData _getBenefitIcon(BenefitType type) {
    switch (type) {
      case BenefitType.pointsBonus:
        return Icons.stars;
      case BenefitType.multiplier:
        return Icons.close_fullscreen;
      case BenefitType.feature:
        return Icons.extension;
      case BenefitType.access:
        return Icons.lock_open;
      case BenefitType.cosmetic:
        return Icons.palette;
    }
  }

  String _getBenefitTypeLabel(BenefitType type) {
    switch (type) {
      case BenefitType.pointsBonus:
        return 'Points Bonus';
      case BenefitType.multiplier:
        return 'Multiplier';
      case BenefitType.feature:
        return 'Feature Access';
      case BenefitType.access:
        return 'Special Access';
      case BenefitType.cosmetic:
        return 'Cosmetic';
    }
  }

  String _formatPrivilegeName(String privilegeName) {
    return privilegeName.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // Action methods
  void _shareTierProgress(TierState state) {
    final tierName = state.currentTier?.level.displayName ?? 'Unknown';
    final level = state.currentTier?.level.level ?? 1;
    final progress = state.progressToNext;
    
    Share.share(
      'I\'m currently at $tierName (Level $level) in Dabbler! ${progress.toStringAsFixed(1)}% progress to the next tier! 🚀',
    );
  }

  void _showTierHistory(TierState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTierHistoryModal(state.history),
    );
  }

  Widget _buildTierHistoryModal(List<TierHistoryEntry> history) {
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
          
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Tier History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // History list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return _buildHistoryEntry(entry, index == 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(TierHistoryEntry entry, bool isLatest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLatest ? _getTierColor(entry.tierLevel).withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest ? _getTierColor(entry.tierLevel) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTierColor(entry.tierLevel).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTierIcon(entry.tierLevel),
              color: _getTierColor(entry.tierLevel),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.tierLevel.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTierColor(entry.tierLevel),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CURRENT',
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
                
                Text(
                  'Achieved on ${_formatHistoryDate(entry.achievedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                Text(
                  '${entry.pointsAtAchievement.toStringAsFixed(0)} points • ${entry.benefitsUnlocked} benefits unlocked',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getTierColor(entry.tierLevel),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTierDetails(TierLevel tier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getTierIcon(tier), color: _getTierColor(tier)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tier.displayName,
                style: TextStyle(color: _getTierColor(tier)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level: ${tier.level}'),
            const SizedBox(height: 8),
            Text('Points Required: ${tier.minPoints.toStringAsFixed(0)}+'),
            const SizedBox(height: 4),
            Text('Points Range: ${tier.minPoints.toStringAsFixed(0)} - ${tier.maxPoints.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBenefitsGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Benefits Guide'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benefits Types:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Points Bonus: Extra points for daily activities'),
            Text('• Multiplier: Increased rewards from achievements'),
            Text('• Feature: Access to special app features'),
            Text('• Access: Exclusive content and areas'),
            Text('• Cosmetic: Visual customization options'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatHistoryDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}