import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum AchievementSortOption {
  pointsHighToLow,
  pointsLowToHigh,
  rarityRareToCommon,
  rarityCommonToRare,
  progressHighToLow,
  progressLowToHigh,
  nameAToZ,
  nameZToA,
  categoryGrouped,
  dateEarnedNewest,
  dateEarnedOldest,
}

class AchievementSortOptions extends StatelessWidget {
  final AchievementSortOption currentSort;
  final ValueChanged<AchievementSortOption> onSortChanged;
  final bool showProgressOptions;
  final bool showDateOptions;

  const AchievementSortOptions({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    this.showProgressOptions = true,
    this.showDateOptions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.sort,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.grey[600],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Points section
          _buildSectionHeader('Points'),
          _buildSortOption(
            title: 'Highest Points First',
            subtitle: 'Most valuable achievements',
            option: AchievementSortOption.pointsHighToLow,
            icon: Icons.trending_up,
          ),
          _buildSortOption(
            title: 'Lowest Points First',
            subtitle: 'Easier achievements first',
            option: AchievementSortOption.pointsLowToHigh,
            icon: Icons.trending_down,
          ),
          
          const SizedBox(height: 16),
          
          // Rarity section
          _buildSectionHeader('Rarity'),
          _buildSortOption(
            title: 'Rarest First',
            subtitle: 'Most exclusive achievements',
            option: AchievementSortOption.rarityRareToCommon,
            icon: Icons.diamond,
          ),
          _buildSortOption(
            title: 'Most Common First',
            subtitle: 'Widely earned achievements',
            option: AchievementSortOption.rarityCommonToRare,
            icon: Icons.groups,
          ),
          
          if (showProgressOptions) ...[
            const SizedBox(height: 16),
            
            // Progress section
            _buildSectionHeader('Progress'),
            _buildSortOption(
              title: 'Highest Progress First',
              subtitle: 'Nearly completed achievements',
              option: AchievementSortOption.progressHighToLow,
              icon: Icons.percent,
            ),
            _buildSortOption(
              title: 'Lowest Progress First',
              subtitle: 'Recently started achievements',
              option: AchievementSortOption.progressLowToHigh,
              icon: Icons.play_arrow,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Name section
          _buildSectionHeader('Name'),
          _buildSortOption(
            title: 'A to Z',
            subtitle: 'Alphabetical order',
            option: AchievementSortOption.nameAToZ,
            icon: Icons.sort_by_alpha,
          ),
          _buildSortOption(
            title: 'Z to A',
            subtitle: 'Reverse alphabetical',
            option: AchievementSortOption.nameZToA,
            icon: Icons.sort_by_alpha,
          ),
          
          const SizedBox(height: 16),
          
          // Category section
          _buildSectionHeader('Category'),
          _buildSortOption(
            title: 'Group by Category',
            subtitle: 'Organize by achievement type',
            option: AchievementSortOption.categoryGrouped,
            icon: Icons.category,
          ),
          
          if (showDateOptions) ...[
            const SizedBox(height: 16),
            
            // Date section
            _buildSectionHeader('Date Earned'),
            _buildSortOption(
              title: 'Recently Earned',
              subtitle: 'Latest achievements first',
              option: AchievementSortOption.dateEarnedNewest,
              icon: Icons.schedule,
            ),
            _buildSortOption(
              title: 'Oldest Earned',
              subtitle: 'First achievements earned',
              option: AchievementSortOption.dateEarnedOldest,
              icon: Icons.history,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String title,
    required String subtitle,
    required AchievementSortOption option,
    required IconData icon,
  }) {
    return Builder(
      builder: (BuildContext context) {
        final isSelected = currentSort == option;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSortChanged(option),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).primaryColor.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ).animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: 200.ms,
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to get sort option display info
  static SortOptionInfo getSortInfo(AchievementSortOption option) {
    switch (option) {
      case AchievementSortOption.pointsHighToLow:
        return SortOptionInfo(
          title: 'Points (High to Low)',
          icon: Icons.trending_up,
        );
      case AchievementSortOption.pointsLowToHigh:
        return SortOptionInfo(
          title: 'Points (Low to High)',
          icon: Icons.trending_down,
        );
      case AchievementSortOption.rarityRareToCommon:
        return SortOptionInfo(
          title: 'Rarity (Rare First)',
          icon: Icons.diamond,
        );
      case AchievementSortOption.rarityCommonToRare:
        return SortOptionInfo(
          title: 'Rarity (Common First)',
          icon: Icons.groups,
        );
      case AchievementSortOption.progressHighToLow:
        return SortOptionInfo(
          title: 'Progress (High to Low)',
          icon: Icons.percent,
        );
      case AchievementSortOption.progressLowToHigh:
        return SortOptionInfo(
          title: 'Progress (Low to High)',
          icon: Icons.play_arrow,
        );
      case AchievementSortOption.nameAToZ:
        return SortOptionInfo(
          title: 'Name (A to Z)',
          icon: Icons.sort_by_alpha,
        );
      case AchievementSortOption.nameZToA:
        return SortOptionInfo(
          title: 'Name (Z to A)',
          icon: Icons.sort_by_alpha,
        );
      case AchievementSortOption.categoryGrouped:
        return SortOptionInfo(
          title: 'Category',
          icon: Icons.category,
        );
      case AchievementSortOption.dateEarnedNewest:
        return SortOptionInfo(
          title: 'Recently Earned',
          icon: Icons.schedule,
        );
      case AchievementSortOption.dateEarnedOldest:
        return SortOptionInfo(
          title: 'Oldest Earned',
          icon: Icons.history,
        );
    }
  }
}

class SortOptionInfo {
  final String title;
  final IconData icon;

  const SortOptionInfo({
    required this.title,
    required this.icon,
  });
}

// Quick sort button for inline use
class QuickSortButton extends StatelessWidget {
  final AchievementSortOption currentSort;
  final ValueChanged<AchievementSortOption> onSortChanged;
  final List<AchievementSortOption> availableOptions;

  const QuickSortButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.availableOptions,
  });

  @override
  Widget build(BuildContext context) {
    final currentInfo = AchievementSortOptions.getSortInfo(currentSort);
    
    return PopupMenuButton<AchievementSortOption>(
      onSelected: onSortChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentInfo.icon,
              size: 16,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              currentInfo.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
      itemBuilder: (context) => availableOptions.map((option) {
        final info = AchievementSortOptions.getSortInfo(option);
        return PopupMenuItem<AchievementSortOption>(
          value: option,
          child: Row(
            children: [
              Icon(
                info.icon,
                size: 16,
                color: currentSort == option 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Text(
                info.title,
                style: TextStyle(
                  fontWeight: currentSort == option 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                  color: currentSort == option 
                      ? Theme.of(context).primaryColor 
                      : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}